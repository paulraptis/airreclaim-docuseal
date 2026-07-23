# frozen_string_literal: true

class SubmitFormCompletedDownloadController < ApplicationController
  skip_before_action :authenticate_user!
  skip_authorization_check

  TTL = 40.minutes
  FILES_TTL = 5.minutes

  def index
    signature_valid = load_submitter

    return head :not_found unless @submitter
    return head :not_found if download_blocked?(@submitter)

    Submissions::EnsureResultGenerated.call(@submitter)

    last_submitter = @submitter.submission.submitters.where.not(completed_at: nil).order(:completed_at).last

    return head :not_found unless last_submitter

    Submissions::EnsureResultGenerated.call(last_submitter)

    return head :not_found unless download_authorized?(last_submitter, signature_valid)

    respond_with_documents(last_submitter)
  end

  private

  def load_submitter
    signed_submitter = Submitter.find_signed(params[:sig], purpose: :download_completed) if params[:sig].present?
    signature_valid = signed_submitter&.slug == submitter_slug
    @submitter = signature_valid ? signed_submitter : Submitter.find_by(slug: submitter_slug)

    signature_valid
  end

  def submitter_slug
    params[:submit_form_slug] || params[:submitter_slug] || params[:submitter_id]
  end

  def canonical_signer_request?
    params[:submit_form_slug].present?
  end

  def download_blocked?(submitter)
    submitter.declined_at? ||
      submitter.submission.archived_at? ||
      submitter.submission.expired? ||
      submitter.submission.template&.archived_at? ||
      submitter.account.archived_at?
  end

  def download_authorized?(submitter, signature_valid)
    return true if signature_valid || current_user_submitter?(submitter)

    unless Submitters::AuthorizedForForm.call(@submitter, current_user, request)
      Rollbar.info("2FA download error: #{submitter.id}") if defined?(Rollbar)

      return false
    end

    return true if canonical_signer_request? || submitter.completed_at >= TTL.ago

    Rollbar.info("TTL: #{submitter.id}") if defined?(Rollbar)

    false
  end

  def respond_with_documents(submitter)
    if params[:combined] == 'true'
      respond_with_combined(submitter)
    else
      render json: Submitters.build_document_urls(submitter, ttl: FILES_TTL)
    end
  end

  def respond_with_combined(submitter)
    url = Submitters.build_combined_url(submitter, ttl: FILES_TTL)

    if url
      render json: [url]
    else
      head :not_found
    end
  end

  def current_user_submitter?(submitter)
    current_user && current_ability.can?(:read, submitter)
  end
end

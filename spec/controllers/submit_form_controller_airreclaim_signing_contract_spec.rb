# frozen_string_literal: true

RSpec.describe SubmitFormController do
  let(:show_view) { Rails.root.join('app/views/submit_form/show.html.erb').read }
  let(:submission_view) { Rails.root.join('app/views/submit_form/_submission_form.html.erb').read }
  let(:form_component) { Rails.root.join('app/javascript/submission_form/form.vue').read }
  let(:completed_component) { Rails.root.join('app/javascript/submission_form/completed.vue').read }
  let(:form_styles) { Rails.root.join('app/javascript/form.scss').read }
  let(:form_layout) { Rails.root.join('app/views/layouts/form.html.erb').read }
  let(:completed_view) { Rails.root.join('app/views/submit_form/completed.html.erb').read }
  let(:download_element) { Rails.root.join('app/javascript/elements/download_button.js').read }
  let(:attribution_view) { Rails.root.join('app/views/shared/_airreclaim_attribution.html.erb').read }

  it 'preserves the DocuSeal signer integration identifiers and endpoints' do
    expect(show_view).to include('id="scrollbox"')
    expect(show_view).to include('id="signing_form_header"')
    expect(show_view).to include('id="complete_button_container"')
    expect(show_view).to include('id="complete_button_container_scroll"')
    expect(submission_view).to include('data-submitter=')
    expect(submission_view).to include('data-fields=')
    expect(submission_view).to include('data-values=')
    expect(submission_view).to include('data-completed-redirect-url=')
    completed_download_dataset = 'data-completed-download-url="<%= submit_form_documents_path(submitter.slug) %>"'

    expect(submission_view).to include(completed_download_dataset)
    expect(form_component).to include('id="complete_form_button"')
    expect(form_component).to include('id="submit_form_button"')
    expect(form_component).to include(':action="submitPath"')
  end

  it 'uses the canonical completed-document route and an accessible retry state' do
    expect(completed_component).to include('fetch(this.completedDownloadUrl')
    expect(completed_component).not_to include('/submitters/${this.submitterSlug}/download')
    expect(completed_component).not_to include("alert(this.t('failed_to_download_files'))")
    expect(completed_component).to include('role="alert"')
    expect(completed_component).to include('this.downloadError = true')
    expect(completed_component).to include('this.isDownloading = false')
    expect(completed_component).to include('if (!response.ok)')
    expect(completed_component).to include('if (!blob.size)')
    expect(completed_view).to include('data-src="<%= submit_form_documents_path(@submitter.slug) %>"')
    expect(completed_view).not_to include('@submitter.completed_at > 30.minutes.ago')
    expect(completed_view).to include('data-download-error role="alert"')
    expect(completed_view).to include('data-download-retry')
    expect(download_element).not_to include('alert(')
    expect(download_element).to include('if (!response.ok)')
    expect(download_element).to include("contentType.includes('application/pdf')")
    expect(download_element).to include('if (!blob.size)')
    expect(download_element).to include('this.setLoading(false)')
  end

  it 'keeps a 24px desktop and 16px mobile gap between the action bar and document' do
    expect(show_view).not_to include('margin-bottom: -16px')
    expect(form_styles).to include('margin-bottom: 1.5rem;')
    expect(form_styles).to match(/@media \(max-width: 767px\).*?#signing_form_header \{.*?margin-bottom: 1rem;/m)
  end

  it 'keeps the document name readable beside the mobile signing actions' do
    expect(show_view).to include('text-base leading-tight md:text-2xl')
    expect(show_view).to include('min-w-0 flex-1')
    expect(show_view).to include('break-words')
    expect(show_view).not_to include('text-overflow: ellipsis; white-space: nowrap;')
  end

  it 'keeps CSRF protection and visible DocuSeal attribution while applying AirReclaim branding' do
    expect(form_layout).to include('csrf_meta_tags')
    expect(form_layout).to include('airreclaim-form-shell')
    expect(form_layout).to include('@submitter&.submission')
    expect(form_layout).to include("\"\#{signer_document_name} | AirReclaim\"")
    expect(form_layout).to include('flush: true')
    expect(show_view).to include("render('submit_form/banner')")
    expect(show_view).to include("render 'shared/airreclaim_attribution'")
    expect(attribution_view).to include('DocuSeal')
    expect(attribution_view).to include('AIRRECLAIM_DOCUSEAL_SOURCE_URL')
  end
end

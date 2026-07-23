# frozen_string_literal: true

RSpec.describe 'Completed signer document downloads' do
  let(:account) { create(:account) }
  let(:author) { create(:user, account:) }
  let(:folder) { create(:template_folder, account:, author:) }
  let(:template) { create(:template, account:, author:, folder:) }
  let(:submission) { create(:submission, template:, created_by_user: author) }
  let(:submitter) do
    create(:submitter,
           submission:,
           uuid: submission.template_submitters.first['uuid'],
           completed_at:)
  end
  let(:completed_at) { 5.minutes.ago }
  let(:document_urls) { ['/rails/active_storage/blobs/proxy/fresh-token/signed-document.pdf'] }

  before do
    author
    allow(Submissions::EnsureResultGenerated).to receive(:call)
    allow(Submitters::AuthorizedForForm).to receive(:call).and_return(true)
    allow(Submitters).to receive(:build_document_urls).and_return(document_urls)
  end

  it 'downloads immediately after signing through the canonical signer route' do
    get submit_form_documents_path(submitter.slug)

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(document_urls)
    expect(Submitters).to have_received(:build_document_urls).with(submitter, ttl: 5.minutes)
  end

  context 'when the authorized signer link is older than the legacy 40-minute window' do
    let(:completed_at) { 41.minutes.ago }

    it 'issues fresh short-lived document URLs through the canonical signer route' do
      get submit_form_documents_path(submitter.slug)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq(document_urls)
      expect(Submitters).to have_received(:build_document_urls).with(submitter, ttl: 5.minutes)
    end

    it 'retains the stricter time limit on the legacy route' do
      get "/submitters/#{submitter.slug}/download"

      expect(response).to have_http_status(:not_found)
    end
  end

  it 'accepts a valid signed completed-download URL' do
    signed_id = submitter.signed_id(purpose: :download_completed)

    get "/submitters/#{submitter.slug}/download", params: { sig: signed_id }

    expect(response).to have_http_status(:ok)
  end

  it 'rejects an invalid signer slug' do
    get submit_form_documents_path('invalid-signer-slug')

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects a signer that fails form authorization or 2FA' do
    allow(Submitters::AuthorizedForForm).to receive(:call).and_return(false)

    get submit_form_documents_path(submitter.slug)

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects a declined signer' do
    submitter.update!(declined_at: Time.current)

    get submit_form_documents_path(submitter.slug)

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects an archived submission' do
    submission.update!(archived_at: Time.current)

    get submit_form_documents_path(submitter.slug)

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects an expired submission' do
    submission.update!(expire_at: 1.minute.ago)

    get submit_form_documents_path(submitter.slug)

    expect(response).to have_http_status(:not_found)
  end

  it 'rejects an archived template' do
    submission.template.update!(archived_at: Time.current)

    get submit_form_documents_path(submitter.slug)

    expect(response).to have_http_status(:not_found)
  end
end

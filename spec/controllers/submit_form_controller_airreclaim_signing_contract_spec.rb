# frozen_string_literal: true

RSpec.describe SubmitFormController do
  let(:show_view) { Rails.root.join('app/views/submit_form/show.html.erb').read }
  let(:submission_view) { Rails.root.join('app/views/submit_form/_submission_form.html.erb').read }
  let(:form_component) { Rails.root.join('app/javascript/submission_form/form.vue').read }
  let(:form_layout) { Rails.root.join('app/views/layouts/form.html.erb').read }
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
    expect(form_component).to include('id="complete_form_button"')
    expect(form_component).to include('id="submit_form_button"')
    expect(form_component).to include(':action="submitPath"')
  end

  it 'keeps CSRF protection and visible DocuSeal attribution while applying AirReclaim branding' do
    expect(form_layout).to include('csrf_meta_tags')
    expect(form_layout).to include('airreclaim-form-shell')
    expect(show_view).to include("render('submit_form/banner')")
    expect(show_view).to include("render 'shared/airreclaim_attribution'")
    expect(attribution_view).to include('DocuSeal')
    expect(attribution_view).to include('AIRRECLAIM_DOCUSEAL_SOURCE_URL')
  end
end

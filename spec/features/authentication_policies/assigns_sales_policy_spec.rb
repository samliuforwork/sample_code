require 'rails_helper'

describe "return delivered order", type: :feature do
  include_context 'valid sales people'
  include_context 'valid price lists'
  include_context "valid session"
  include_context 'order with verifying settlement'
  let(:unit_nums) { %w[100 303] }

  context 'with settlement contribution status verified' do
    before(:each) do
      create_test_session
      order.settlement.update!(status: 'verified')
      visit order.settlement.edit_path
    end

    context 'given roles sales_assistant(main_assistant), admin, and finance' do
      %w[sales_assistant admin finance].each do |role|
        it 'show save button in page' do
          expect(page).to have_button(I18n.t('Save'))
        end
      end
    end

    context 'given roles sales_assistant(assigned_assistant)' do
      let(:assigned_assistant) { create(:user, unit_nums: ['203'], roles: roles) }

      before :each do
        Rails.cache.write(session_key, [assigned_assistant.id, platform.id])
        visit order.settlement.edit_path
      end

      it 'do not show save button in page' do
        expect(page).not_to have_button(I18n.t('Save'))
      end
    end
  end

  context 'with settlement contribution status correcting' do
    before(:each) do
      create_test_session
      order.settlement.update!(status: 'correcting')
      visit order.settlement.edit_path
    end

    context 'given roles sales_assistant(main_assistant), admin, and finance' do
      %w[sales_assistant admin finance].each do |role|
        it 'shows draft and submit button in page' do
          expect(page).to have_button(I18n.t('Save as Draft'))
          expect(page).to have_button(I18n.t('Submit Settlement'))
        end
      end
    end

    context 'given roles sales_assistant(assigned_assistant)' do
      let(:assigned_assistant) { create(:user, unit_nums: ['203'], roles: roles) }

      before :each do
        Rails.cache.write(session_key, [assigned_assistant.id, platform.id])
        visit order.settlement.edit_path
      end

      it 'do not shows draft and submit button in page' do
        expect(page).not_to have_button(I18n.t('Save as Draft'))
        expect(page).not_to have_button(I18n.t('Submit Settlement'))
      end
    end
  end

  context 'with settlement contribution status done' do
    before(:each) do
      create_test_session
      order.settlement.update!(status: 'verified')
      order.settlement.update!(status: 'auditing')
      order.settlement.update!(status: 'done')
      visit order.settlement.edit_path
    end

    context 'given roles sales_assistant(main_assistant), admin, and finance' do
      %w[sales_assistant admin finance].each do |role|
        it 'shows save button in page' do
          expect(page).to have_button(I18n.t('Save'))
        end
      end
    end

    context 'given roles sales_assistant(assigned_assistant)' do
      let(:assigned_assistant) { create(:user, unit_nums: ['203'], roles: roles) }

      before :each do
        Rails.cache.write(session_key, [assigned_assistant.id, platform.id])
        visit order.settlement.edit_path
      end

      it 'do not shows save button in page' do
        expect(page).not_to have_button(I18n.t('Save'))
      end
    end
  end
end

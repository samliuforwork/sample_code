require 'rails_helper'

describe 'finance report exporter', type: :feature do
  include DownloadHelpers
  include_context 'valid session'
  let(:roles) { %w[auditor] }
  let(:path) { 'spec/fixtures/files/downloads/finance_report.xlsx' }
  before(:all) { Timecop.freeze(Time.utc(2022, 07, 01, 4, 0, 0)) }
  after(:all) { Timecop.return }

  describe 'payment sheet' do
    include_context 'finance report payment sheet'
    let(:sheet) { Roo::Spreadsheet.open(path).sheet('payment') }
    let(:ignored_columns) { %i[parent_uuid order_all_delivered_at order_all_returned_at settled_month periods settled_year instalment invoice_title invoice_date invoice_serial register].map { |column| I18n.t("xlsx:#{column}") } }
    let(:parse_columns) { (sheet.row(1) - ignored_columns).each_with_object({}) { |column, hash| hash[column] = column }.except(ignored_columns) }
    let(:sheet_columns) { remove_header(sheet, parse_columns) }

    before do
      create_test_session
      download_finance_report_report
    end

    context 'when parse payment sheet' do
      it 'shows expected payment sheet columns in row 2' do
        expect(sheet_columns.first).to eq(expected_payment_columns.first.transform_keys { |key| I18n.t("xlsx:#{key}") })
      end

      it 'shows expected payment sheet columns in row 3' do
        expect(sheet_columns.last).to eq(expected_payment_columns.last.transform_keys { |key| I18n.t("xlsx:#{key}") })
      end
    end
  end

  describe 'reconciliation sheet' do
    include_context 'finance report reconciliation sheet'
    let(:sheet) { Roo::Spreadsheet.open(path).sheet('reconciliation') }
    let(:ignored_columns) { %i[parent_uuid settled_year settled_month invoice_date invoice_serial original_trial_ended_at trial_ended_at order_all_delivered_at order_all_returned_at settlement_status_changed_at order_status_updated_at].map { |column| I18n.t("xlsx:#{column}") } }
    let(:parse_columns) { (sheet.row(2) - ignored_columns).each_with_object({}) { |column, hash| hash[column] = column } }
    let(:sheet_columns) { remove_header(sheet, parse_columns) }

    before do
      create_test_session
      download_finance_report_report
    end

    context 'when parse reconciliation sheet' do
      it 'shows expected reconciliation sheet columns in row 3' do
        expect(sheet_columns.first).to eq(expected_reconciliation_columns.first.transform_keys { |key| I18n.t("xlsx:#{key}") })
      end

      it 'shows expected reconciliation sheet columns in row 4' do
        expect(sheet_columns.last).to eq(expected_reconciliation_columns.last.transform_keys { |key| I18n.t("xlsx:#{key}") })
      end
    end
  end

  after :each do
    File.delete(path) if File.exist?(path)
  end
end

def download_finance_report_report
  order
  visit finance_report_path
  js_fill_in('input[name=order_startdate]', '2020-05-07')
  js_fill_in('input[name=order_enddate]', '2052-05-07')
  find('button[type=submit]', text: I18n.t(:Submit)).click
  trigger_click('#settlement_all')
  trigger_click('#export_report')
  wait_for_download(1)
end

def remove_header(sheet, parse_columns)
  rows = []
  sheet.each_with_index(parse_columns) do |sheet_columns, index|
    next if index.zero? # skip header

    rows << sheet_columns
  end

  rows
end

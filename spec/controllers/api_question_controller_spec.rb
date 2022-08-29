require 'rails_helper'

describe Api::QuestionsController, type: :controller do
  describe 'PATCH #report' do
    context 'when report question successfully' do
      context 'with format json' do
        let(:question) { create(:question, inappropriate: false) }
        let(:teacher) { create(:user, :teacher) }
        let(:token) { create(:token, user: teacher) }
        let(:params) {{ token: token.uuid }}

        it 'reports question' do
          expect {
            patch "/api/questions/#{question.id}/report_inappropriate.json", params: params
            question.reload
          }.to change(question, :inappropriate).from(false).to(true)
          expect(JSON.parse(response.body)).to eq(JSON.parse(question.to_json(serialize_options_with_answer)))
          expect(response.code).to eq('200')
        end
      end
    end

    context 'when report question failed' do
      let(:question) { create(:question, inappropriate: false) }
      context 'with error about permissions' do
        context 'when user without token' do
          it 'raise Unauthorized Unknown token' do
            patch "/api/questions/#{question.id}/report_inappropriate"
            expect(response.body).to eq('Unknown token')
            expect(response.code).to eq('400')
          end
        end

        context 'when given token not in database' do
          let(:params) {{ token: 'token.uuid' }}

          it 'raise Unauthorized Invalid token' do
            patch "/api/questions/#{question.id}/report_inappropriate", params: params
            expect(response.body).to eq('Invalid token')
            expect(response.code).to eq('400')
          end
        end

        context 'when user roles is student' do
          let(:student) { create(:user, :student) }
          let(:token) { create(:token, user: student) }
          let(:params) {{ token: token.uuid }}

          it 'raise Not authorization role' do
            patch "/api/questions/#{question.id}/report_inappropriate", params: params
            expect(response.body).to eq('Not authorization role')
            expect(response.code).to eq('401')
          end
        end
      end

      context 'with error about incomplete parameter' do
        context 'without question_id or question not found' do
          let(:teacher) { create(:user, :teacher) }
          let(:token) { create(:token, user: teacher) }
          let(:params) {{ token: token.uuid }}

          it 'raise question not found' do
            patch "/api/questions/:id/report_inappropriate", params: params
            expect(response.body).to eq('question not found')
            expect(response.code).to eq('400')
          end
        end
      end
    end
  end
end

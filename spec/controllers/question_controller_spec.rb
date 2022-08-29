require 'rails_helper'

describe QuestionsController, type: :controller do
  describe 'POST #search' do
    let(:params) { { query: 'basic_question' } }

    context 'POST jsonHttpRequest format questions search' do
      it 'partial renders questions_list' do
        post '/questions/search', params: params, xhr: true
        expect(response).to render_template('questions/_questions_list')
      end
    end
    
    context 'POST html format questions search' do
      it 'renders question search template' do
        post '/questions/search.html', params: params
        expect(response.headers['Content-Type']).to eq('text/html; charset=utf-8')
        expect(response).to render_template('questions/search')
      end
    end

    context 'with basic question search' do
      context 'when params status is 0, renders question not answered' do
        let!(:basic_question_DEC) { create(:question, content: 'basic_question', created_at: '2021-12-31 00:00:00') }
        let!(:basic_question_JAN) { create(:question, content: 'basic_question', created_at: '2021-01-01 00:00:00') }
        let!(:question_not_search) { create(:question, content: 'question_not_search') }
        let(:params) { { subject_id:'', grade_id:'', status:'0', query:'basic_question' } }

        context 'POST json format questions search' do
          it 'renders question instance variable to json' do
            post '/questions/search.json', params: params
            expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
            expect(Question.count).to eq(3)
            expect(assigns(:questions).first).to eq(basic_question_DEC)
            expect(assigns(:questions).last).to eq(basic_question_JAN)
            expect(assigns(:questions)).not_to include(question_not_search)
            expect(response.body).to eq(assigns(:questions).to_json(serialize_options_for_search))
          end
        end
    
        context 'POST json format questions search' do
          it 'renders question instance variable to json' do
            post '/questions/search.json', params: params
            expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
            expect(assigns(:questions).first).to eq(basic_question_DEC)
            expect(assigns(:questions).last).to eq(basic_question_JAN)
            expect(response.body).to eq(assigns(:questions).to_json(serialize_options_for_search))
          end
        end
      end

      context 'when params status is 1, renders answered question' do
        let!(:basic_question_DEC) { create(:question_with_answers, content: 'basic_question', created_at: '2021-12-31 00:00:00') }
        let!(:basic_question_JAN) { create(:question_with_answers, content: 'basic_question', created_at: '2021-01-01 00:00:00') }
        let!(:question_not_search) { create(:question, content: 'question_not_search') }
        let(:params) { { query: 'basic_question' } }

        context 'POST json format questions search' do
          it 'renders question instance variable to json' do
            post '/questions/search.json', params: params
            expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
            expect(Question.count).to eq(3)
            expect(assigns(:questions).first).to eq(basic_question_DEC)
            expect(assigns(:questions).last).to eq(basic_question_JAN)
            expect(assigns(:questions)).not_to include(question_not_search)
            expect(response.body).to eq(assigns(:questions).to_json(serialize_options_for_search))
          end
        end
    
        context 'POST json format questions search' do
          it 'renders question instance variable to json' do
            post '/questions/search.json', params: params
            expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
            expect(assigns(:questions).first).to eq(basic_question_DEC)
            expect(assigns(:questions).last).to eq(basic_question_JAN)
            expect(response.body).to eq(assigns(:questions).to_json(serialize_options_for_search))
          end
        end
      end
    end

    context 'with advance question search' do
      context 'when params only have advance and grade_id' do
        let(:math) { create(:subject, :senior) }
        let!(:advance_question_DEC) { create(:question_with_answers, content: 'advance_question', subject: math, created_at: '2021-12-31 00:00:00') }
        let!(:advance_question_JAN) { create(:question_with_answers, content: 'advance_question', subject: math, created_at: '2021-01-01 00:00:00') }
        let!(:question_not_search) { create(:question, content: 'question_not_search') }
        let(:params) {{ query: 'advance_question', advance: true, grade_id: math.grade.id }}

        context 'POST json format questions search' do
          it 'renders question instance variable to json' do
            post '/questions/search.json', params: params
            expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
            expect(Question.count).to eq(3)
            expect(assigns(:questions).first).to eq(advance_question_DEC)
            expect(assigns(:questions).last).to eq(advance_question_JAN)
            expect(assigns(:questions)).not_to include(question_not_search)
            expect(response.body).to eq(assigns(:questions).to_json(serialize_options_for_search))
          end
        end
      end

      context 'when params have advance, subject_id, status' do
        let(:math) { create(:subject, :senior) }
        let!(:advance_question_DEC) { create(:question, content: 'advance_question', subject: math,created_at: '2021-12-31 00:00:00') }
        let!(:advance_question_JAN) { create(:question, content: 'advance_question', subject: math,created_at: '2021-01-01 00:00:00') }
        let!(:question_not_search) { create(:question, content: 'question_not_search', subject: math) }
        let(:params) {{ query: 'advance_question', advance: true,  subject_id: math.id, status: 'unresolved'}}

        context 'POST json format questions search' do
          it 'renders question instance variable to json' do
            post '/questions/search.json', params: params
            expect(response.headers['Content-Type']).to eq('application/json; charset=utf-8')
            expect(Question.count).to eq(3)
            expect(assigns(:questions).first).to eq(advance_question_DEC)
            expect(assigns(:questions).last).to eq(advance_question_JAN)
            expect(assigns(:questions)).not_to include(question_not_search)
            expect(response.body).to eq(assigns(:questions).to_json(serialize_options_for_search))
          end
        end
      end
    end
  end

  describe 'GET #unlock' do
    let(:student) { create(:user, :student) }
    let(:locker_not_current_user) { create(:user, :student) }
    let(:question) { create(:question, locked_at: 25.minutes.ago, locker: locker_not_current_user) }
    let(:question_unlock) { create(:question, locked_at: 15.minutes.ago, locker:student) }

    before(:each) do
      login(student)
    end

    context 'when question unlock successfully' do
      before(:each) do
        get "/questions/#{question_unlock.id}/unlock"
      end

      it 'updates question locker and locked_at be nil ' do
        expect(question_unlock.reload.locker).to be nil
        expect(question_unlock.reload.locked_at).to be nil
      end

      it 'redirect_to question_url' do
        expect(response).to redirect_to(assigns(:question))
      end
    end
    
    context 'when question unlock failed' do
      before(:each) do
        get "/questions/#{question.id}/unlock"
      end

      it 'do not clear question locker and locked_at' do
        expect(question.reload.locker).not_to be_nil
        expect(question.locked_at).not_to be_nil
      end

      it 'redirect_to question_url' do
        expect(response).to redirect_to(assigns(:question))
      end
    end
  end
end
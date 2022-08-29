require 'rails_helper'

describe "Question features", type: :feature do
  describe 'questions #new #create' do
    let(:student) { create(:user, :student) }
    before(:each) do
      login(student)
      visit '/questions/new'
    end

    context 'when enter questions new page', js: true do
      it 'renders question new page template' do
        contents = %w[grade subject content primary junior]
        contents.each do |content|
          expect(page.find("#content")).to have_content(I18n.t(content))
        end
        expect(current_path).to eq("/questions/new")
        expect(page).to have_css("img[src='/images/button/ask_question_title.png']")
        expect(page).to have_css("input[src='/images/button/submit_ask.png']")
        expect(page).to have_css("img[src='/images/button/cancel_ask.png']")
      end
    end

    context 'when question create successfully', js: true do
      let!(:subject) { create(:subject, grade: Grade.find_by_name("primary_school")) }

      before(:each) do
        expect(Question.count).to eq(0)
        find("#grade_2").click
        fill_in_rich_text_area "question_action_content", with: "question content"
        execute_script(%Q{document.querySelector('input[src="/images/button/submit_ask.png"]').click()})
      end

      it 'created question has attributes with given iframe content and redirect to question show' do
        expect(Question.count).to eq(1)
        expect(current_path).to eq("/questions/#{Question.first.id}")
        expect(Question.first.content).to include("question content")
        expect(Question.first.title).to eq("#{I18n.t(subject.grade.name)}/#{subject.name}")
        expect(page).to have_content("question content")
      end
    end

    context 'when question create failed', js: true do
      context 'with blank subject' do
        before(:each) do
          find('iframe')
          execute_script("$('iframe').contents().find('body').append('question content')")
          execute_script(%Q{document.querySelector('input[src="/images/button/submit_ask.png"]').click()})
        end

        it 'raises error subject not found' do
          expect(page).to have_content(I18n.t('Subject not found'))
        end
      end

      context 'with blank content' do
        let!(:subject) { create(:subject, grade: Grade.find_by_name("primary_school")) }
        let!(:computer) { create(:subject, grade: Grade.find_by_name("junior_high_school")) }
        before(:each) do
          find("#grade_2").click
          execute_script(%Q{document.querySelector('input[src="/images/button/submit_ask.png"]').click()})
        end
        
        it 'raises error content can not be blank' do
          expect(page).to have_content(I18n.t('content can not be blank'))
        end
      end

      context 'when click cancel_ask button' do
        it 'redirect to user show page' do
          execute_script(%Q{document.querySelector('img[src="/images/button/cancel_ask.png"]').click()})
          expect(current_path).to eq(root_path)
        end
      end
    end
  end
end

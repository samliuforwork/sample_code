require 'faker'

FactoryBot.define do
  factory :question do
    sequence(:title) { |n| "question_title#{n}" }
    sequence(:content) { |n| "question_content#{n}" }
    point { 100 }
    subject
    user

    factory :question_with_provenances do
      transient do
        languages_count { 3 }
      end

      after(:create) do |question, evaluator|
        create_list(:provenance, evaluator.languages_count, question: question)
      end
    end

    factory :question_with_answers do
      transient do
        languages_count { 1 }
      end

      after(:create) do |question, evaluator|
        create_list(:answer, evaluator.languages_count, question: question)
      end
    end
  end
end
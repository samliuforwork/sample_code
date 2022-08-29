class QuestionsController < ApplicationController
  before_action :check_user_points, :check_question_subject
  def create
    return if performed?

    if current_user.check_daily_question_quota.present?
      redirect_to(request.referer.presence || root_path, notice: current_user.check_daily_question_quota)
      return
    end

    begin
      Question.transaction do
        @question = create_question_with_attributes
        current_user.consume_points(params[:question][:point].to_i)

        Delayed::Job.enqueue(RemandPointsJob.new(@question.id), { priority: 0, run_at: params[:question][:point].to_i > 100 ? 1.hour.from_now : 1.day.from_now })
      end

      log_activity(:log_question, @question.id.to_s)

      # update subscribed channels
      current_user.update_devices
      broadcast_channels(question: @question, msgtype: '0', object_ids: ["s#{@question.subject_id}"])
    rescue StandardError => e
      logger.error e.message
    end

    respond_to do |format|
      if @question.save
        format.html { redirect_to(@question, notice: t(:was_successfully_created)) }
        format.json { render json: @question, status: :created, location: @question }
      else
        format.html { render action: 'new' }
        format.json { render json: @question.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def check_user_points
    return unless current_user.points < params[:question][:point].to_i

    flash[:notice] = t(:not_enough_point)
    redirect_to action: 'new'
  end

  def check_question_subject
    subject = Subject.find_by_id(params[:subject_id])
    return unless subject.nil?

    flash[:notice] = t(:subject_no_found)
    redirect_to action: 'new'
  end
end

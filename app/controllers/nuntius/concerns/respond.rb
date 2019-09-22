# frozen_string_literal: true

module Nuntius
  module Concerns
    module Respond
      # Informs the user and redirects when needed
      #
      # @param result [Boolean] was update or create succesful
      # @param path [URL] where to redirect to
      # @param notice [String] What to show on success
      # @param error [String] What to show on error
      # @param action [Symbol] What to render
      # @param model [Object] What model to use for generating the notice/error flashes
      #
      def respond(result, path: nil, notice: nil, error: nil, action: :index, model: nil)
        human_model_name = model ? model.model_name.human.downcase : Nuntius.const_get(self.class.name.demodulize.gsub(/Controller$/, '').singularize).model_name.human.downcase
        if result
          if params[:commit] == 'continue'
            flash.now[:notice] = (notice || I18n.t('nuntius.flash.notice', model: human_model_name))
          else
            flash[:notice] = notice || I18n.t('nuntius.flash.notice', model: human_model_name)
            if path
              redirect_to(path) && return
            else
              redirect_to(action: action) && return
            end
          end
        else
          flash.now[:error] = (error || I18n.t('nuntius.flash.error', model: human_model_name))
        end
        render action
      end
    end
  end
end

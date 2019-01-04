class WelcomeController < ApplicationController
    def search
        render plain: "No results for '#{params[:q]}'"
    end
end

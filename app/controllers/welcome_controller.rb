class WelcomeController < ApplicationController
    def search
        puts request.env.select {|k,v|
            k.match("^HTTP.*|^CONTENT.*|^REMOTE.*|^REQUEST.*|^AUTHORIZATION.*|^SCRIPT.*|^SERVER.*")
        }
        render plain: "No results for '#{params[:q]}'"
    end
end

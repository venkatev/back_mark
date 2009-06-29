# = Back mark plugin
#
# Mark pages with labels that can be linked back from future pages as back
# links
#
# Also remembers the last accessed non Create/Update/Delete page (as in CRUD).
# For instance, a user is viewing items index, and navigates to 'new item'
# page. Once he is done with the creation of the item (i.e., POST to items/create),
# it would be nice if the user is taken to the index page rather than the 'new'
# page, which was the LAST VISITED page. Hence, such CUD actions are
# *_not_remembered_*.
#
# Author    ::  Vikram Venkatesan  (mailto:vikram.venkatesan@yahoo.com)
#
module BackMark
  module ControllerMethods
    # Pages/Actions which we don't want to remember. We wouldnt ideally want to
    # link back to new, edit, etc.,. We would only want to provide a link to the
    # page that led to those pages
    # 
    IGNORE_ACTIONS = %w(new edit create update destroy)
    
    def self.included(controller)
      controller.send :include, InstanceMethods
      controller.before_filter :back_mark_pages
    end

    module InstanceMethods
      # Marks the current url with the given label. Invoke from an action with
      # a meaningful label, if you want that page to be linked back from future
      # pages
      #
      # ==== Params
      # label       ::  label for the back mark
      # url_to_mark ::  the url to remember instead of the current request
      #                 url
      # mark_now    ::  Mark the location so that the back link can be rendered
      #                 in the current action
      #
      # ===== Examples
      #   back_mark("Inbox")
      #   back_mark("Home")
      #   back_mark("Login", '/login', true)
      #
      def back_mark(label, url_to_mark = request.url, mark_now = false)
        # Ignore AJAX requests since they cannot be linked back.
        return if request.xhr?

        # Mark directly into back_url directly so that we can render in the
        # current action itself.
        if mark_now
          session[:back_label] = session[:prev_label] = label
          session[:back_url] = session[:prev_label] = url_to_mark
          @back_marked = true
          return
        end

        # Set back url and label from previously back marked page
        session[:back_url] = session[:prev_url]
        session[:back_label] = session[:prev_label]

        # Mark the current page
        session[:prev_url] = url_to_mark
        session[:prev_label] = label
        @back_marked = true
      end

      # Redirect to the back link stored in the session or redirect to the
      # default url passed.
      #
      # NOTE: We redirect back to the url stored by the filter. Not the last
      # back_marked url.
      #
      def redirect_to_back_mark_or_default(default_url)
        redirect_to((@marked_in_filter ? session[:filter_back_url] :
          session[:filter_prev_url]) || default_url)

        session[:filter_back_url] = nil
      end
    end

    # Add this as a before filter for marking the current request url
    def back_mark_pages(options = {})
      options_to_use = {:force_mark => false}.merge(options)

      # Ignore AJAX requests since they cannot be linked back.
      # Also ignore actions in IGNORE_ACTIONS
      return if request.xhr? || (!options_to_use[:force_mark] && IGNORE_ACTIONS.include?(params[:action]))

      session[:filter_back_url] = session[:filter_prev_url]
      session[:filter_prev_url] = options_to_use[:url] || request.url
      @marked_in_filter = true
    end
  end
  
  module ViewMethods
    # Returns the stored back url or the given default_url if the former is
    # empty
    #
    def back_url_or_default(default_url)
      (@marked_in_filter ? session[:filter_back_url] :
        session[:filter_prev_url]) || default_url
    end

    # Returns the last back_marked page url
    def back_url
      @back_marked ? session[:back_url] : session[:prev_url]
    end

    # Returns the last back_marked label
    def back_label
      @back_marked ? session[:back_label] : session[:prev_label]
    end

    # Renders a link back to the previous page stored in the session with the
    # stored label if both of them are available
    #
    def render_back_link
      # Dont render back link if the back url is the same as the current page
      return if back_url == request.url

      if back_url && back_label
        link_to "&laquo; Back to '#{back_label}'", back_url, :id => 'back_link'
      end
    end
  end
end

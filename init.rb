ActionController::Base.send :include, BackMark::ControllerMethods
ActionView::Base.send       :include, BackMark::ViewMethods
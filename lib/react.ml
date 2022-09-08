include Core
module Hooks = Hooks

module Dom = struct
  include Dom

  module Dsl = struct
    module Html = Dom_html
    module Svg = Dom_svg
  end
end

module Event = Event
module Router = Router

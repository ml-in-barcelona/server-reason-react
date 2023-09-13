type t = Dom.trackEvent;
type track; /* TODO: VideoTrack or AudioTrack or TextTrack */

include Webapi__Dom__Event.Impl({
  type nonrec t = t;
});

[@mel.new] external make: string => t = "TrackEvent";
[@mel.new] external makeWithOptions: (string, Js.t({..})) => t = "TrackEvent";

[@mel.get] external track: t => track = "track";

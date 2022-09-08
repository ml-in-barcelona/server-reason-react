const LEAFLET_CSS_URL = "https://unpkg.com/leaflet@1.6.0/dist/leaflet.css";
const STYLESHEET = `
#map {
  width: 100%;
  height: 100%;
  overflow: hidden;
}
.leaflet-top .leaflet-control {
  margin-top: 2em;
}
.leaflet-left .leaflet-control {
  margin-left: 2em;
}
.leaflet-bottom .leaflet-control {
  margin-bottom: 2em;
}
.leaflet-right .leaflet-control {
  margin-right: 2em;
}
.leaflet-control.leaflet-control-attribution {
  margin: 0;
  margin-top: -1.5em; /* make this "transparent" to other controls margins  */
}
.leaflet-control-zoom,
.leaflet-touch .leaflet-control-zoom {
  box-shadow: none;
  border: none;
}
.leaflet-control-zoom > a.leaflet-control-zoom-in,
.leaflet-control-zoom > a.leaflet-control-zoom-out,
.leaflet-touch .leaflet-control-zoom > a.leaflet-control-zoom-in,
.leaflet-touch .leaflet-control-zoom > a.leaflet-control-zoom-out {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 1.5em;
  height: 1.5em;
  font-size: 26px;
  font-weight: normal;
  color: #E16246;
  border-radius: 50%;
  box-shadow: 0 1px 5px rgb(0 0 0 / 10%);
}
.leaflet-control-zoom > a:first-child {
  margin-bottom: .25em;
}
`;

// leafy-map

class Map extends HTMLElement {
  static get observedAttribtues() {
    return ["lat", "lng", "zoom"];
  }

  get lat() {
    return this.getAttribute("lat") || 51;
  }
  get lng() {
    return this.getAttribute("lng") || 0;
  }
  get zoom() {
    return this.getAttribute("zoom") || -1;
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "lat":
      case "lng":
        this.map && this.map.setView([this.lat, this.lng]);
        break;

      case "zoom":
        this.map && this.map.setZoom(this.zoom);
        break;
    }
  }

  constructor() {
    super();

    this.render();

    // ensure we've rendered before initializing
    setTimeout(() => {
      this.initMap();
      this.initView();
      this.initChildren();
    });
  }

  render() {
    this.attachShadow({ mode: "open" });

    const styleEl = document.createElement("style");
    styleEl.textContent = STYLESHEET;
    const leafletStyleEl = document.createElement("link");
    leafletStyleEl.setAttribute("rel", "stylesheet");
    leafletStyleEl.setAttribute("href", LEAFLET_CSS_URL);

    this.mapEl = document.createElement("div");
    this.mapEl.setAttribute("id", "map");

    this.shadowRoot.append(leafletStyleEl, styleEl, this.mapEl);
  }

  initMap() {
    if (this.map) this.map.remove();

    this.map = L.map(this.mapEl, {
      zoomControl: false,
    });

    L.control
      .zoom({
        position: "bottomright",
      })
      .addTo(this.map);

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution:
        'Map data &copy; <a href="http://openstreetmap.org.>OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery &copy; <a href="http://mapbox.com">Mapbox</a>',
      maxZoom: 18,
    }).addTo(this.map);
  }

  initView() {
    this.map.setView([this.lat, this.lng], this.zoom);
    if (this.zoom == -1) {
      this.map.fitWorld({ animate: false });
    }
  }

  initChildren() {
    for (let child of this.children) {
      child.container = this.map;
    }

    this.mutationObserver = new MutationObserver((mutations) =>
      mutations.forEach((mutation) => {
        for (let child of mutation.addedNodes) {
          child.container = this.map;
        }

        for (let child of mutation.removedNodes) {
          child.container = null;
        }
      })
    );
    this.mutationObserver.observe(this, { childList: true });
  }
}

customElements.define("leafy-map", Map);

// Feature

class Feature extends HTMLElement {
  static get observedAttributes() {
    return ["data", "tooltip", "tooltip-open"];
  }

  get tooltip() {
    return this.getAttribute("tooltip");
  }

  get tooltipOpen() {
    return this.getAttribute("tooltip-open");
  }

  attributeChangedCallback(name, oldValue, newValue) {
    switch (name) {
      case "tooltip":
      case "tooltip-open":
        this._setPopup();
        break;
    }
  }

  get feature() {
    return this._feature;
  }
  set feature(new_feature) {
    if (this.container && this._feature) {
      this.container.removeLayer(this._feature);
    }

    this._feature = new_feature;

    if (this.container && this._feature) {
      this._feature.addTo(this.container);
      this._setPopup();
    }
  }

  get container() {
    return this._container;
  }
  set container(new_container) {
    if (this._container && this.feature) {
      this._container.removeLayer(this.feature);
    }

    this._container = new_container;

    if (this._container && this.feature) {
      this.feature.addTo(this._container);
      this._setPopup();
    }
  }

  _setPopup() {
    if (this.feature) {
      this.feature.unbindTooltip();

      if (this.tooltip) {
        this.feature.bindTooltip(this.tooltip, {
          direction: "top",
        });

        if (this.tooltipOpen) {
          this.feature.openTooltip();
        }
      }
    }
  }
}

// InteractiveFeature

class InteractiveFeature extends Feature {
  connectedCallback() {}

  get feature() {
    return this._feature;
  }
  set feature(new_feature) {
    if (this.container && this._feature) {
      this.container.removeLayer(this._feature);
    }

    this._feature = new_feature;

    if (this._feature) {
      [
        "click",
        "dblclick",
        "mousedown",
        "mouseup",
        "mouseover",
        "mouseout",
        "contextmenu",
      ].forEach((eventName) =>
        this._feature.on(eventName, (event) =>
          this.dispatchEvent(new MouseEvent(eventName, event))
        )
      );
    }

    if (this.container && this._feature) {
      this._feature.addTo(this.container);
      this._setPopup();
    }
  }
}

// FeatureGroup

class FeatureGroup extends Feature {
  static get observedAttributes() {
    return ["zoom-to-fit", ...Feature.observedAttributes];
  }

  get zoomToFit() {
    return this.getAttribute("zoom-to-fit") || false;
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "zoom-to-fit":
        if (this.zoomToFit) {
          this.fitBounds();
        }
        break;
    }
  }

  constructor() {
    super();

    this.feature = L.featureGroup();

    for (let child of this.children) {
      child.container = this.feature;
    }

    this.mutationObserver = new MutationObserver((mutations) =>
      mutations.forEach((mutation) => {
        for (let child of mutation.addedNodes) {
          child.container = this.feature;
        }

        for (let child of mutation.removedNodes) {
          child.container = null;
        }

        this.fitBounds();
      })
    );
    this.mutationObserver.observe(this, { childList: true });

    this.fitBounds();
  }

  get container() {
    return super.container;
  }
  set container(new_container) {
    super.container = new_container;

    if (this.zoomToFit) {
      this.fitBounds();
    }
  }

  fitBounds() {
    if (this.container) {
      let bounds = this.feature.getBounds();
      if (bounds.isValid()) {
        this.container.fitBounds(bounds, {
          paddingBottomRight: L.point(0, 32),
          animate: false,
        });
      }
    }
  }
}

customElements.define("leafy-feature-group", FeatureGroup);

// Marker

class Marker extends InteractiveFeature {
  static get observedAttributes() {
    return ["lat", "lng", ...Feature.observedAttributes];
  }

  get lat() {
    return this.getAttribute("lat") || 0;
  }
  get lng() {
    return this.getAttribute("lng") || 0;
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "lat":
      case "lng":
        this.feature.setLatLng(L.latLng(this.lat, this.lng));
        break;
    }
  }

  constructor() {
    super();

    this.feature = L.marker([this.lat, this.lng]);
  }
}

customElements.define("leafy-marker", Marker);

// Path

class Path extends InteractiveFeature {
  static get observedAttributes() {
    return [
      "stroke",
      "stroke-width",
      "stroke-dasharray",
      "fill",
      "fill-opacity",
      "class",
      ...Feature.observedAttributes,
    ];
  }

  get pathOptions() {
    let fill = this.getAttribute("fill");
    return {
      color: this.getAttribute("stroke") || "red",
      weight: this.getAttribute("stroke-width") || 3,
      dashArray: this.getAttribute("stroke-dasharray"),
      fill: fill == null ? true : !!fill,
      fillColor: fill || "red",
      fillOpacity: this.getAttribute("fill-opacity") || 0.2,
      className: this.getAttribute("class"),
    };
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "stroke":
      case "stroke-width":
      case "stroke-dasharray":
      case "fill":
      case "fill-opacity":
      case "class":
        this.feature && this.feature.setStyle(this.pathOptions);
        break;
    }
  }
}

// Polyline

class Polyline extends Path {
  static get observedAttributes() {
    return ["zoom-to-fit", ...Path.observedAttributes];
  }

  get zoomToFit() {
    return this.getAttribute("zoom-to-fit") || false;
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "zoom-to-fit":
        if (this.zoomToFit) {
          this.fitBounds();
        }
        break;
    }
  }

  get feature() {
    return super.feature;
  }
  set feature(new_feature) {
    super.feature = new_feature;

    if (this.zoomToFit) {
      this.fitBounds();
    }
  }

  get container() {
    return super.container;
  }
  set container(new_container) {
    super.container = new_container;

    if (this.zoomToFit) {
      this.fitBounds();
    }
  }

  fitBounds() {
    if (this.container && this.feature) {
      let bounds = this.feature.getBounds();
      if (bounds.isValid()) {
        this.container.fitBounds(bounds, {
          paddingBottomRight: L.point(0, 32),
          animate: false,
        });
      }
    }
  }
}

// leafy-circle

class Circle extends Polyline {
  static get observedAttributes() {
    return ["lat", "lng", "radius", ...Polyline.observedAttributes];
  }

  get lat() {
    return this.getAttribute("lat") || 0;
  }
  get lng() {
    return this.getAttribute("lng") || 0;
  }
  get radius() {
    return this.getAttribute("radius") || 0;
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "lat":
      case "lng":
        this.feature.setLatLng(L.latLng(this.lat, this.lng));
        break;

      case "radius":
        this.feature.setRadius(this.radius);
        break;
    }
  }

  constructor() {
    super();

    this.feature = L.circle(
      [this.lat, this.lng],
      this.radius,
      this.pathOptions
    );
  }
}

customElements.define("leafy-circle", Circle);

// leafy-geojson

class Geojson extends Polyline {
  static get observedAttributes() {
    return ["data", ...Polyline.observedAttributes];
  }

  get data() {
    try {
      return JSON.parse(this.getAttribute("data"));
    } catch (e) {
      return null;
    }
  }

  attributeChangedCallback(name, oldValue, newValue) {
    super.attributeChangedCallback(name, oldValue, newValue);

    switch (name) {
      case "data":
        this.feature = L.geoJSON(this.data, this.pathOptions);
        break;
    }
  }

  constructor() {
    super();

    this.feature = L.geoJSON(this.data, this.pathOptions);
  }
}

customElements.define("leafy-geojson", Geojson);

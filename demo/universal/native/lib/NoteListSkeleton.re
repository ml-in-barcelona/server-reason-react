[@react.component]
let make = () => {
  <div>
    <ul className="notes-list skeleton-container">
      <li className="v-stack">
        <div
          className="sidebar-note-list-item skeleton"
          style={ReactDOM.Style.make(~height="5em", ())}
        />
      </li>
      <li className="v-stack">
        <div
          className="sidebar-note-list-item skeleton"
          style={ReactDOM.Style.make(~height="5em", ())}
        />
      </li>
      <li className="v-stack">
        <div
          className="sidebar-note-list-item skeleton"
          style={ReactDOM.Style.make(~height="5em", ())}
        />
      </li>
    </ul>
  </div>;
};

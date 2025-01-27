[@react.component]
let make = () => {
  <div>
    <ul className="p-2 skeleton-container">
      <li className="v-stack">
        <div
          className="relative mb-3 p-4 w-full flex justify-between items-start flex-wrap max-h-[100px] transition-[max-height] duration-250 ease-out scale-100 skeleton"
          style={ReactDOM.Style.make(~height="5em", ())}
        />
      </li>
      <li className="v-stack">
        <div
          className="relative mb-3 p-4 w-full flex justify-between items-start flex-wrap max-h-[100px] transition-[max-height] duration-250 ease-out scale-100 skeleton"
          style={ReactDOM.Style.make(~height="5em", ())}
        />
      </li>
      <li className="v-stack">
        <div
          className="relative mb-3 p-4 w-full flex justify-between items-start flex-wrap max-h-[100px] transition-[max-height] duration-250 ease-out scale-100 skeleton"
          style={ReactDOM.Style.make(~height="5em", ())}
        />
      </li>
    </ul>
  </div>;
};

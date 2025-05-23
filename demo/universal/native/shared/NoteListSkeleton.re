[@react.component]
let make = () => {
  <div className="mt-8">
    <ul className="flex flex-col">
      <li className="v-stack">
        <div
          className={Cx.make([
            Theme.background(Theme.Color.Gray4),
            "animate-pulse relative mb-3 p-4 w-full flex justify-between items-start flex-wrap h-[150px] transition-[max-height] ease-out rounded-md",
          ])}
        />
      </li>
      <li className="v-stack">
        <div
          className={Cx.make([
            Theme.background(Theme.Color.Gray4),
            "animate-pulse relative mb-3 p-4 w-full flex justify-between items-start flex-wrap h-[150px] transition-[max-height] ease-out rounded-md",
          ])}
        />
      </li>
      <li className="v-stack">
        <div
          className={Cx.make([
            Theme.background(Theme.Color.Gray4),
            "animate-pulse relative mb-3 p-4 w-full flex justify-between items-start flex-wrap h-[150px] transition-[max-height] ease-out rounded-md",
          ])}
        />
      </li>
    </ul>
  </div>;
};

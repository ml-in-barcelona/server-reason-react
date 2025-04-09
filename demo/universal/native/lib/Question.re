type response = {message: string};
[@warning "-27"];
[@react.client.component]
let make = (~onClick: React.Event.Mouse.t => unit) => {
  let (showAnswer, setShowAnswer) = RR.useStateValue(false);
  <div>
    <div>
      <Text>
        "What's is the answer to the life, the universe and everything?"
      </Text>
    </div>
    <Spacer bottom=4 />
    <button
      className="font-mono border-2 py-1 px-2 rounded-lg bg-yellow-950 border-yellow-700 text-yellow-200 hover:bg-yellow-800"
      type_="submit"
      onClick={e => {
        setShowAnswer(!showAnswer);
        onClick(e);
      }}>
      {React.string("Click me to show the answer!")}
    </button>
    <Spacer bottom=4 />
    <div> <Text> {showAnswer ? "42" : "???"} </Text> </div>
  </div>;
};

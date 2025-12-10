/* Scenario: Props Heavy
      Components with many HTML attributes/props
      Purpose: Test attribute serialization performance
   */

module HeavyDiv = {
  [@react.component]
  let make = (~id, ~children) => {
    <div
      id={Printf.sprintf("heavy-div-%d", id)}
      className="heavy-component p-4 m-2 bg-white rounded-lg shadow-md border border-gray-200 hover:shadow-lg transition-shadow duration-300"
      dataTestid={Printf.sprintf("test-heavy-%d", id)}
      role="article"
      ariaLabel={Printf.sprintf("Heavy component number %d", id)}
      ariaDescribedby={Printf.sprintf("desc-%d", id)}
      tabIndex=0
      style={ReactDOM.Style.make(
        ~backgroundColor="#ffffff",
        ~padding="16px",
        ~margin="8px",
        ~borderRadius="8px",
        ~boxShadow="0 2px 4px rgba(0,0,0,0.1)",
        ~transition="all 0.3s ease",
        ~cursor="pointer",
        ~userSelect="none",
        ~overflow="hidden",
        ~position="relative",
        ~zIndex="1",
        (),
      )}>
      children
    </div>;
  };
};

module HeavyInput = {
  [@react.component]
  let make = (~id, ~label) => {
    <div className="form-group mb-4">
      <label
        htmlFor={Printf.sprintf("input-%d", id)}
        className="block text-sm font-medium text-gray-700 mb-1">
        {React.string(label)}
      </label>
      <input
        type_="text"
        id={Printf.sprintf("input-%d", id)}
        name={Printf.sprintf("field_%d", id)}
        className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
        placeholder={Printf.sprintf("Enter %s...", label)}
        autoComplete="off"
        autoCapitalize="none"
        autoCorrect="off"
        spellCheck=false
        required=true
        minLength=1
        maxLength=100
        pattern="[A-Za-z0-9]+"
        title="Only alphanumeric characters"
        ariaLabel={Printf.sprintf("Input for %s", label)}
        ariaRequired=true
        dataTestid={Printf.sprintf("input-test-%d", id)}
        style={ReactDOM.Style.make(
          ~width="100%",
          ~padding="8px 12px",
          ~fontSize="14px",
          ~lineHeight="1.5",
          ~borderWidth="1px",
          ~borderStyle="solid",
          ~borderColor="#d1d5db",
          ~borderRadius="6px",
          ~outline="none",
          (),
        )}
      />
    </div>;
  };
};

module HeavyButton = {
  [@react.component]
  let make = (~id, ~text, ~variant) => {
    let (bgColor, textColor) =
      switch (variant) {
      | `primary => ("bg-blue-600", "text-white")
      | `secondary => ("bg-gray-200", "text-gray-800")
      | `danger => ("bg-red-600", "text-white")
      | `success => ("bg-green-600", "text-white")
      };

    <button
      type_="button"
      id={Printf.sprintf("btn-%d", id)}
      className={Cx.make([
        "inline-flex items-center justify-center px-4 py-2 rounded-md font-medium",
        "focus:outline-none focus:ring-2 focus:ring-offset-2",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        "transition-colors duration-200",
        bgColor,
        textColor,
      ])}
      disabled=false
      ariaPressed="false"
      ariaLabel={Printf.sprintf("Button: %s", text)}
      ariaDescribedby={Printf.sprintf("btn-desc-%d", id)}
      dataTestid={Printf.sprintf("btn-test-%d", id)}
      role="button"
      tabIndex=0
      style={ReactDOM.Style.make(
        ~display="inline-flex",
        ~alignItems="center",
        ~justifyContent="center",
        ~padding="8px 16px",
        ~fontSize="14px",
        ~fontWeight="500",
        ~lineHeight="1.25",
        ~borderRadius="6px",
        ~border="none",
        ~cursor="pointer",
        ~textDecoration="none",
        (),
      )}>
      {React.string(text)}
    </button>;
  };
};

module HeavyTable = {
  [@react.component]
  let make = (~rows, ~cols) => {
    <div className="overflow-x-auto">
      <table
        className="min-w-full divide-y divide-gray-200"
        role="grid"
        ariaLabel="Data table"
        ariaRowcount=rows
        ariaColcount=cols>
        <thead className="bg-gray-50">
          <tr role="row">
            {React.array(
               Array.init(cols, col =>
                 <th
                   key={Int.to_string(col)}
                   scope="col"
                   role="columnheader"
                   ariaSort="none"
                   ariaColindex={col + 1}
                   className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
                   style={ReactDOM.Style.make(
                     ~padding="12px 24px",
                     ~textAlign="left",
                     ~fontSize="12px",
                     ~fontWeight="500",
                     ~textTransform="uppercase",
                     ~letterSpacing="0.05em",
                     (),
                   )}>
                   {React.string(Printf.sprintf("Column %d", col + 1))}
                 </th>
               ),
             )}
          </tr>
        </thead>
        <tbody className="bg-white divide-y divide-gray-200">
          {React.array(
             Array.init(rows, row =>
               <tr
                 key={Int.to_string(row)}
                 role="row"
                 ariaRowindex={row + 1}
                 className={row mod 2 == 0 ? "bg-white" : "bg-gray-50"}>
                 {React.array(
                    Array.init(cols, col =>
                      <td
                        key={Int.to_string(col)}
                        role="gridcell"
                        ariaColindex={col + 1}
                        className="px-6 py-4 whitespace-nowrap text-sm text-gray-900"
                        dataTestid={Printf.sprintf("cell-%d-%d", row, col)}
                        style={ReactDOM.Style.make(
                          ~padding="16px 24px",
                          ~whiteSpace="nowrap",
                          ~fontSize="14px",
                          (),
                        )}>
                        {React.string(
                           Printf.sprintf("R%dC%d", row + 1, col + 1),
                         )}
                      </td>
                    ),
                  )}
               </tr>
             ),
           )}
        </tbody>
      </table>
    </div>;
  };
};

/* Different sizes for comparison */
module Small = {
  [@react.component]
  let make = () => {
    <div className="p-4">
      {React.array(
         Array.init(10, i =>
           <HeavyDiv key={Int.to_string(i)} id=i>
             <HeavyInput id=i label={Printf.sprintf("Field %d", i)} />
             <div className="flex gap-2 mt-2">
               <HeavyButton id={i * 3} text="Primary" variant=`primary />
               <HeavyButton
                 id={i * 3 + 1}
                 text="Secondary"
                 variant=`secondary
               />
               <HeavyButton id={i * 3 + 2} text="Delete" variant=`danger />
             </div>
           </HeavyDiv>
         ),
       )}
    </div>;
  };
};

module Medium = {
  [@react.component]
  let make = () => {
    <div className="p-4">
      {React.array(
         Array.init(50, i =>
           <HeavyDiv key={Int.to_string(i)} id=i>
             <HeavyInput id=i label={Printf.sprintf("Field %d", i)} />
             <HeavyButton id=i text="Submit" variant=`primary />
           </HeavyDiv>
         ),
       )}
    </div>;
  };
};

module Large = {
  [@react.component]
  let make = () => {
    <div className="p-4"> <HeavyTable rows=100 cols=10 /> </div>;
  };
};

[@react.component]
let make = () => <Medium />;

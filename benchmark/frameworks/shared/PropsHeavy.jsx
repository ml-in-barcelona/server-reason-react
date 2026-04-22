// Port of benchmark/scenarios/PropsHeavy.re
// Purpose: test attribute serialization performance

import React from "react";
import { cx } from "./cx.js";

const HeavyDiv = ({ id, children }) => (
  <div
    id={`heavy-div-${id}`}
    className="heavy-component p-4 m-2 bg-white rounded-lg shadow-md border border-gray-200 hover:shadow-lg transition-shadow duration-300"
    data-testid={`test-heavy-${id}`}
    role="article"
    aria-label={`Heavy component number ${id}`}
    aria-describedby={`desc-${id}`}
    tabIndex={0}
    style={{
      backgroundColor: "#ffffff",
      padding: "16px",
      margin: "8px",
      borderRadius: "8px",
      boxShadow: "0 2px 4px rgba(0,0,0,0.1)",
      transition: "all 0.3s ease",
      cursor: "pointer",
      userSelect: "none",
      overflow: "hidden",
      position: "relative",
      zIndex: "1",
    }}
  >
    {children}
  </div>
);

const HeavyInput = ({ id, label }) => (
  <div className="form-group mb-4">
    <label
      htmlFor={`input-${id}`}
      className="block text-sm font-medium text-gray-700 mb-1"
    >
      {label}
    </label>
    <input
      type="text"
      id={`input-${id}`}
      name={`field_${id}`}
      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
      placeholder={`Enter ${label}...`}
      autoComplete="off"
      autoCapitalize="none"
      autoCorrect="off"
      spellCheck={false}
      required
      minLength={1}
      maxLength={100}
      pattern="[A-Za-z0-9]+"
      title="Only alphanumeric characters"
      aria-label={`Input for ${label}`}
      aria-required="true"
      data-testid={`input-test-${id}`}
      style={{
        width: "100%",
        padding: "8px 12px",
        fontSize: "14px",
        lineHeight: "1.5",
        borderWidth: "1px",
        borderStyle: "solid",
        borderColor: "#d1d5db",
        borderRadius: "6px",
        outline: "none",
      }}
    />
  </div>
);

const HeavyButton = ({ id, text, variant }) => {
  let bgColor, textColor;
  switch (variant) {
    case "primary":
      bgColor = "bg-blue-600";
      textColor = "text-white";
      break;
    case "secondary":
      bgColor = "bg-gray-200";
      textColor = "text-gray-800";
      break;
    case "danger":
      bgColor = "bg-red-600";
      textColor = "text-white";
      break;
    case "success":
      bgColor = "bg-green-600";
      textColor = "text-white";
      break;
  }
  return (
    <button
      type="button"
      id={`btn-${id}`}
      className={cx([
        "inline-flex items-center justify-center px-4 py-2 rounded-md font-medium",
        "focus:outline-none focus:ring-2 focus:ring-offset-2",
        "disabled:opacity-50 disabled:cursor-not-allowed",
        "transition-colors duration-200",
        bgColor,
        textColor,
      ])}
      disabled={false}
      aria-pressed="false"
      aria-label={`Button: ${text}`}
      aria-describedby={`btn-desc-${id}`}
      data-testid={`btn-test-${id}`}
      role="button"
      tabIndex={0}
      style={{
        display: "inline-flex",
        alignItems: "center",
        justifyContent: "center",
        padding: "8px 16px",
        fontSize: "14px",
        fontWeight: "500",
        lineHeight: "1.25",
        borderRadius: "6px",
        border: "none",
        cursor: "pointer",
        textDecoration: "none",
      }}
    >
      {text}
    </button>
  );
};

const HeavyTable = ({ rows, cols }) => (
  <div className="overflow-x-auto">
    <table
      className="min-w-full divide-y divide-gray-200"
      role="grid"
      aria-label="Data table"
      aria-rowcount={rows}
      aria-colcount={cols}
    >
      <thead className="bg-gray-50">
        <tr role="row">
          {Array.from({ length: cols }, (_, col) => (
            <th
              key={String(col)}
              scope="col"
              role="columnheader"
              aria-sort="none"
              aria-colindex={col + 1}
              className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"
              style={{
                padding: "12px 24px",
                textAlign: "left",
                fontSize: "12px",
                fontWeight: "500",
                textTransform: "uppercase",
                letterSpacing: "0.05em",
              }}
            >
              {`Column ${col + 1}`}
            </th>
          ))}
        </tr>
      </thead>
      <tbody className="bg-white divide-y divide-gray-200">
        {Array.from({ length: rows }, (_, row) => (
          <tr
            key={String(row)}
            role="row"
            aria-rowindex={row + 1}
            className={row % 2 === 0 ? "bg-white" : "bg-gray-50"}
          >
            {Array.from({ length: cols }, (_, col) => (
              <td
                key={String(col)}
                role="gridcell"
                aria-colindex={col + 1}
                className="px-6 py-4 whitespace-nowrap text-sm text-gray-900"
                data-testid={`cell-${row}-${col}`}
                style={{
                  padding: "16px 24px",
                  whiteSpace: "nowrap",
                  fontSize: "14px",
                }}
              >
                {`R${row + 1}C${col + 1}`}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  </div>
);

export const PropsSmall = () => (
  <div className="p-4">
    {Array.from({ length: 10 }, (_, i) => (
      <HeavyDiv key={String(i)} id={i}>
        <HeavyInput id={i} label={`Field ${i}`} />
        <div className="flex gap-2 mt-2">
          <HeavyButton id={i * 3} text="Primary" variant="primary" />
          <HeavyButton id={i * 3 + 1} text="Secondary" variant="secondary" />
          <HeavyButton id={i * 3 + 2} text="Delete" variant="danger" />
        </div>
      </HeavyDiv>
    ))}
  </div>
);

export const PropsMedium = () => (
  <div className="p-4">
    {Array.from({ length: 50 }, (_, i) => (
      <HeavyDiv key={String(i)} id={i}>
        <HeavyInput id={i} label={`Field ${i}`} />
        <HeavyButton id={i} text="Submit" variant="primary" />
      </HeavyDiv>
    ))}
  </div>
);

export const PropsLarge = () => (
  <div className="p-4">
    <HeavyTable rows={100} cols={10} />
  </div>
);

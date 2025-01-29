let globalStyles = (~background, ~text) => {
  Printf.sprintf(
    {|
.prose h1 {
  font-size: 2.25rem;
  font-weight: bold;
  line-height: 2.5;
}

.prose h2 {
  font-size: 1.875rem;
  font-weight: bold;
  line-height: 2.5;
}

.prose h3 {
  font-size: 1.5rem;
  font-weight: bold;
  line-height: 2.5;
}

.prose h4 {
  font-size: 1.25rem;
  font-weight: bold;
  line-height: 2.5;
}

.prose h5 {
  font-size: 1.125rem;
  font-weight: bold;
  line-height: 2.5;
}

.prose h6 {
  font-size: 1rem;
  font-weight: bold;
  line-height: 2.5;
}

.prose p {
  font-size: 1rem;
  margin-bottom: 1rem;
}

.prose ul, .prose ol {
  padding-left: 2rem;
  margin-bottom: 1rem;
}

.prose li {
  margin-bottom: 0.5rem;
}

.prose blockquote {
  border-left: 4px solid %s;
  padding-left: 1rem;
  margin: 1.5rem 0;
  font-style: italic;
}

.prose pre {
  padding: 1rem;
  margin: 1.5rem 0;
  background-color: %s;
  color: %s;
  border-radius: 0.375rem;
}

.prose code {
  display: block;
  margin: 1rem;
  padding-left: 1rem;
  padding-right: 1rem;
  font-family: monospace;
  background-color: %s;
  color: %s;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
}
|},
    background,
    background,
    text,
    background,
    text,
  );
};

[@react.component]
let make = (~body: string) => {
  <>
    <span
      className={Cx.make([
        "prose",
        "block w-full p-8 rounded-md",
        Theme.background(Theme.Color.Gray4),
        Theme.text(Theme.Color.Gray12),
      ])}
      dangerouslySetInnerHTML={"__html": body}
    />
    <style
      dangerouslySetInnerHTML={
        "__html":
          globalStyles(
            ~background=Theme.Color.gray1,
            ~text=Theme.Color.gray12,
          ),
      }
    />
  </>;
};

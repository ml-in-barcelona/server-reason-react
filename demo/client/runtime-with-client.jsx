window.__webpack_require__ = (id) => {
  let component = window.__exported_components[id];
  console.log("REQUIRE ---");
  console.log(id);
  console.log(component);
  console.log("---");
  if (component === undefined) {
    throw new Error(`Component "${id}" not found`);
  }
  /* return {__esModule: true, default: component}; */
  return component;
};

let React = require("react");
let ReactDOM = require("react-dom/client");
let ReactServerDOM = require("react-server-dom-webpack/client");
let Noter = require("./app/demo/universal/js/Noter.js");

function Use({ promise }) {
  let tree = React.use(promise);
  return tree;
};

try {
  /* let _ = ReactDOM.hydrateRoot(document.getElementById("root"), <Noter.make />); */

  /* let loading
  if (window.srr_stream) {
    loading = ReactServerDOM.createFromReadableStream(
      window.srr_stream.readable_stream,
      {
        callServer: function callServer(id, args) {
          throw new Error(`callServer(${id}, ...): not supported yet`);
        }
      }
    );
    React.startTransition(() => {
      root = ReactDOM.hydrateRoot(document,
        <React.StrictMode>
          <Page loading={loading} />
        </React.StrictMode>
      );
    });
  } */

  /* function fetchRSC(path) {
    return fetch(path, {
      method: 'GET',
      headers: { Accept: 'application/react.component' },
    });
  };

  let loading = ReactServerDOM.createFromFetch(fetchRSC(window.location.href),
    {
      callServer: function callServer(id, args) {
        throw new Error(`callServer(${id}, ...): not supported yet`);
      }
    });
  let root = ReactDOM.createRoot(document);
  root.render(
    <React.StrictMode>
      <Page loading={loading} />
    </React.StrictMode>
  ); */

  /* console.log(window.srr_stream.readable_stream); */

  /*   const mockPayload =
      [`0:["development",[["children","(main)","children","__PAGE__",["__PAGE__",{}],"$L1",[null,"$L2"]]]]`
        , `4:I["(app-pages-browser)/./app/(main)/components/Pronunciation.tsx",["app/(main)/page","static/chunks/app/(main)/page.js"],"Pronunciation"]`
        , `5:I["(app-pages-browser)/./node_modules/next/dist/client/link.js",["app/(main)/not-found","static/chunks/app/(main)/not-found.js"],""]`
        , `6:"$Sreact.suspense"`
        , `1: ["$L3", ["$", "div", null, { "className": "inflate-y-8 md:inflate-y-14 divide-y-2 divide-separator divide-solid", "children": [["$", "header", null, { "children": [["$", "h1", null, { "className": "font-heading text-4xl md:text-7xl mb-4", "children": "I'm Alvar Lagerlöf" }], ["$", "$L4", null, {}], ["$", "h2", null, { "className": "font-subheading text-xl md:text-2xl max-w-[50ch]", "children": ["A developer and designer. My story starts with a $2 computer from a flea market.", " ", ["$", "$L5", null, { "href": "/about", "target": "_self", "rel": "", "className": "text-primary font-semibold no-underline hover:underline", "children": ["Learn more", " â†’"] }]] }]] }], ["$", "div", null, { "className": "inflate-y-8 md:inflate-x-14 md:inflate-y-0 divide-y-2 md:divide-y-0 md:divide-x-2 divide-solid divide-separator divide-solid flex flex-col md:flex-row", "children": [["$", "section", null, { "className": "md:w-1/2", "children": [["$", "h3", null, { "className": "font-heading text-2xl md:text-4xl mb-6 md:mb-8", "children": "Featured projects" }], ["$", "$6", null, { "fallback": ["$", "div", null, { "className": "space-y-8", "children": [["$", "div", null, { "className": "flex flex-row space-x-4 items-center", "children": [["$", "div", null, { "className": "block h-[75px] w-[120px] bg-skeleton rounded-xl" }], ["$", "div", null, { "className": "-m-1 max-w-[calc(100%-130px)]", "children": [["$", "div", null, { "className": "block w-24 max-w-full h-[1.25rem] bg-skeleton rounded mb-3" }], ["$", "div", null, { "className": "block w-[300px] max-w-full h-[1rem] bg-skeleton rounded" }]] }]] }], ["$", "div", null, { "className": "flex flex-row space-x-4 items-center", "children": [["$", "div", null, { "className": "block h-[75px] w-[120px] bg-skeleton rounded-xl" }], ["$", "div", null, { "className": "-m-1 max-w-[calc(100%-130px)]", "children": [["$", "div", null, { "className": "block w-24 max-w-full h-[1.25rem] bg-skeleton rounded mb-3" }], ["$", "div", null, { "className": "block w-[300px] max-w-full h-[1rem] bg-skeleton rounded" }]] }]] }], ["$", "div", null, { "className": "flex flex-row space-x-4 items-center", "children": [["$", "div", null, { "className": "block h-[75px] w-[120px] bg-skeleton rounded-xl" }], ["$", "div", null, { "className": "-m-1 max-w-[calc(100%-130px)]", "children": [["$", "div", null, { "className": "block w-24 max-w-full h-[1.25rem] bg-skeleton rounded mb-3" }], ["$", "div", null, { "className": "block w-[300px] max-w-full h-[1rem] bg-skeleton rounded" }]] }]] }]] }], "children": "$L7" }]] }], ["$", "section", null, { "className": "md:w-1/2", "children": [["$", "h3", null, { "className": "font-heading text-2xl md:text-4xl mb-6 md:mb-8", "children": "Recent blog posts" }], ["$", "ul", null, { "className": "space-y-4 md:space-y-8", "children": ["$", "$6", null, { "fallback": [["$", "div", null, { "className": "space-y-3", "children": [["$", "div", null, { "className": "block w-3/5 h-6 bg-skeleton rounded" }], ["$", "div", null, { "className": "block w-full sm:w-4/5 h-4 bg-skeleton rounded" }]] }], ["$", "div", null, { "className": "space-y-3", "children": [["$", "div", null, { "className": "block w-3/5 h-6 bg-skeleton rounded" }], ["$", "div", null, { "className": "block w-full sm:w-4/5 h-4 bg-skeleton rounded" }]] }], ["$", "div", null, { "className": "space-y-3", "children": [["$", "div", null, { "className": "block w-3/5 h-6 bg-skeleton rounded" }], ["$", "div", null, { "className": "block w-full sm:w-4/5 h-4 bg-skeleton rounded" }]] }], ["$", "div", null, { "className": "space-y-3", "children": [["$", "div", null, { "className": "block w-3/5 h-6 bg-skeleton rounded" }], ["$", "div", null, { "className": "block w-full sm:w-4/5 h-4 bg-skeleton rounded" }]] }]], "children": "$L8" }] }], ["$", "h4", null, { "className": "text-xl font-subheading mt-12", "children": ["$", "$L5", null, { "href": "/blog", "target": "_self", "rel": "", "className": "text-primary font-semibold no-underline hover:underline", "children": ["All posts", " â†’"] }] }]] }]] }]] }], null]`
        , `2: [["$", "meta", "0", { "name": "viewport", "content": "width=device-width, initial-scale=1" }], ["$", "meta", "1", { "charSet": "utf-8" }], ["$", "title", "2", { "children": "Alvar Lagerlöf" }], ["$", "meta", "3", { "name": "description", "content": "Developer and designer from Stockholm" }], ["$", "link", "4", { "rel": "alternate", "type": "application/rss+xml", "href": "https://alvar.dev/feed.xml" }], ["$", "meta", "5", { "property": "og:title", "content": "Alvar Lagerlöf" }], ["$", "meta", "6", { "property": "og:description", "content": "Developer and designer from Stockholm" }], ["$", "meta", "7", { "property": "og:site_name", "content": "alvar.dev" }], ["$", "meta", "8", { "property": "og:image:type", "content": "image/png" }], ["$", "meta", "9", { "property": "og:image", "content": "http://localhost:3001/opengraph-image-12jlf3?bde0b7ba72a51c78" }], ["$", "meta", "10", { "property": "og:image:width", "content": "1200" }], ["$", "meta", "11", { "property": "og:image:height", "content": "630" }], ["$", "meta", "12", { "name": "twitter:card", "content": "summary_large_image" }], ["$", "meta", "13", { "name": "twitter:site", "content": "@alvarlagerlof" }], ["$", "meta", "14", { "name": "twitter:creator", "content": "@alvarlagerlof" }], ["$", "meta", "15", { "name": "twitter:title", "content": "Alvar Lagerlöf" }], ["$", "meta", "16", { "name": "twitter:description", "content": "Developer and designer from Stockholm" }], ["$", "meta", "17", { "name": "twitter:image:type", "content": "image/png" }], ["$", "meta", "18", { "name": "twitter:image", "content": "http://localhost:3001/opengraph-image-12jlf3?bde0b7ba72a51c78" }], ["$", "meta", "19", { "name": "twitter:image:width", "content": "1200" }], ["$", "meta", "20", { "name": "twitter:image:height", "content": "630" }], ["$", "link", "21", { "rel": "icon", "href": "/favicons/favicon.ico" }], ["$", "link", "22", { "rel": "icon", "href": "/favicons/favicon-16x16.png", "sizes": "16x16" }], ["$", "link", "23", { "rel": "icon", "href": "/favicons/favicon-32x32.png", "sizes": "32x32" }], ["$", "link", "24", { "rel": "icon", "href": "/favicons/favicon-192x192.png", "sizes": "192x192" }], ["$", "meta", "25", { "name": "next-size-adjust" }]]`
        , "3: null"
        , `8: [["$", "li", null, { "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold mb-1", "children": ["$", "$L5", null, { "href": "/blog/creating-devtools-for-react-server-components", "children": "Devtools for React Server Components" }] }], ["$", "p", null, { "children": "Visualising RSC streaming" }]] }], ["$", "li", null, { "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold mb-1", "children": ["$", "$L5", null, { "href": "/blog/skeleton-loading-with-suspense-in-next-js-13", "children": "Skeleton Loading with Suspense in Next.js 13" }] }], ["$", "p", null, { "children": "My strategy for handling skeleton loading with Suspense." }]] }], ["$", "li", null, { "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold mb-1", "children": ["$", "$L5", null, { "href": "/blog/tailwindcss-with-next-font", "children": "TailwindCSS with @next/font" }] }], ["$", "p", null, { "children": "Here's how to integrate the new @next/font in Next.js 13 with TailwindCSS." }]] }], ["$", "li", null, { "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold mb-1", "children": ["$", "$L5", null, { "href": "/blog/thoughts-on-photography-tools", "children": "Thoughts on Photography Tools" }] }], ["$", "p", null, { "children": "The tool I'm looking for doesn't seem to exist" }]] }]]`
        , `9: I["(app-pages-browser)/./components/NextSanityImage.tsx", ["app/(main)/page", "static/chunks/app/(main)/page.js"], "NextSanityImage"]`
        , `7: [["$", "ul", null, { "className": "space-y-6 md:space-y-8", "children": [["$", "li", null, { "className": "flex md:flex-row items-start sm:items-center space-x-4", "children": [["$", "div", null, { "className": "min-w-[120px]", "children": ["$", "$L9", null, { "image": { "asset": { "_id": "image-591e25a3975b7cce87abb2652ce75b80001ffbfb-3245x2000-png", "metadata": { "lqip": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAMCAYAAABiDJ37AAAACXBIWXMAAAsTAAALEwEAmpwYAAABD0lEQVQokbVSy0rDUBDNTzXNq72PZBJLa0DUVJOGWGO13XSna3EtuBH8AsG/PDL3FhN3onFxGObAnDnzcFxPwvUHgifh9InxAKJOPxl5FoMI+qGEEAqTqcI4sPZHP4TbM+FwEkQSp3mMfZvhpiJkpDEV6qsBQ0gFKZXhOefIuRAKYSStCRbkDlorPOyO8PGS4+1pgXVJKE4S1AWhPEtQnSdYXxLaitAsyfCrggzXLAmLmTamOkGlcL/N8P58jNfHOa4urOB1SQZceFun2DYp7uoUm1VqOI5tScjncSdoRg6lIbmIuyexHTnWFvoQmbfoOK0Voslh7/2jeIE0u+DjmPf59VH872/z10f/38ceAp9y5aLUMyVXKAAAAABJRU5ErkJggg==", "dimensions": { "width": 3245, "height": 2000 } } } }, "className": "border-2 border-imgborder rounded-xl object-cover", "width": 120, "height": 75, "priority": true, "alt": "Scoreboarder banner" }] }], ["$", "div", null, { "className": "-m-1", "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold break-all mb-1", "children": ["$", "$L5", null, { "href": "https://scoreboarder.xyz", "target": "_blank", "rel": "noreferrer", "children": "Scoreboarder" }] }], ["$", "p", null, { "children": "Website for Discord bot managing scoreboards" }]] }]] }], ["$", "li", null, { "className": "flex md:flex-row items-start sm:items-center space-x-4", "children": [["$", "div", null, { "className": "min-w-[120px]", "children": ["$", "$L9", null, { "image": { "asset": { "_id": "image-a7367e3a460ed37db301d49a7ff011a3367e0bba-902x507-jpg", "metadata": { "lqip": "data:image/jpeg;base64,/9j/2wBDAAYEBQYFBAYGBQYHBwYIChAKCgkJChQODwwQFxQYGBcUFhYaHSUfGhsjHBYWICwgIyYnKSopGR8tMC0oMCUoKSj/2wBDAQcHBwoIChMKChMoGhYaKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCgoKCj/wAARCAALABQDASIAAhEBAxEB/8QAGQAAAgMBAAAAAAAAAAAAAAAAAAcEBQYI/8QAJBAAAgEDAgYDAAAAAAAAAAAAAQIDAAQFERMGBxIhMWEUFTP/xAAVAQEBAAAAAAAAAAAAAAAAAAADBP/EAB0RAAEEAgMAAAAAAAAAAAAAAAABAgMREiExUfD/2gAMAwEAAhEDEQA/AFpwthY722iY3Nqss8m2scqEke61lrwE86R63eLQNIY9Sh1HupvKyCJ8Fjy8aMTdkEka0y7aONNlVjjA+Sx06RRW6y9Yo8G62vuzl/P4/wCry91ZbqzbLletewNFWXMHvxjlPH7HwKKUhXk//9k=", "dimensions": { "width": 902, "height": 507 } } } }, "className": "border-2 border-imgborder rounded-xl object-cover", "width": 120, "height": 75, "priority": true, "alt": "next-banner banner" }] }], ["$", "div", null, { "className": "-m-1", "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold break-all mb-1", "children": ["$", "$L5", null, { "href": "https://github.com/alvarlagerlof/next-banner", "target": "_blank", "rel": "noreferrer", "children": "next-banner" }] }], ["$", "p", null, { "children": "Generate Open Graph images for Next.js at build" }]] }]] }], ["$", "li", null, { "className": "flex md:flex-row items-start sm:items-center space-x-4", "childr


en": [["$", "div", null, { "className": "min-w-[120px]", "children": ["$", "$L9", null, { "image": { "asset": { "_id": "image-b9052ea6be1d8ed8483759d56dd80262800c6114-828x480-png", "metadata": { "lqip": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABQAAAAMCAIAAADtbgqsAAAACXBIWXMAAAsTAAALEwEAmpwYAAAA0UlEQVQokc2RTYvCMBRF+///ldRYRxA0aR1xFpq8j35gWze2mVZSiWJx4cDgZgbO4iZwwn0vwVDR2wR/Lbv6J/gp8D0P9ZPsSuxy05K2bGyqbWosmxb1GfYN6pZ0g7rBg2Wfz2b/zdod0cuupr6A0+eOI5UtkmK5yRZJOo9RSDNZQbjGmUQhIZQcKZz6y1Ju+wyGigNX0aWA0/ZrlNOPmCNFQnlTSJoprwlJU4mhf6hOdn0OY23qchhrt3yDHjyODR7uU3Q5uPJXC3vNP/nn9+Qr6jyYUW4JwRcAAAAASUVORK5CYII=", "dimensions": { "width": 828, "height": 480 } } } }, "className": "border-2 border-imgborder rounded-xl object-cover", "width": 120, "height": 75, "priority": true, "alt": "Neurodiversity Wiki banner" }] }], ["$", "div", null, { "className": "-m-1", "children": [["$", "h4", null, { "className": "text-xl font-subheading font-semibold break-all mb-1", "children": ["$", "$L5", null, { "href": "https://neurodiversity.wiki?utm_source=alvar.dev", "target": "_blank", "rel": "noreferrer", "children": "Neurodiversity Wiki" }] }], ["$", "p", null, { "children": "Website educating the public about neurodiversity" }]] }]] }]] }], ["$", "h4", null, { "className": "text-xl font-subheading mt-12", "children": ["$", "$L5", null, { "href": "/projects", "target": "_self", "rel": "", "className": "text-primary font-semibold no-underline hover:underline", "children": ["All projects", " â†’"] }] }]]`
      ]; */

  /* const mockPayload = [`1:"$Sreact.suspense"\n
0:["$","html",null,{"children":[["$","head",null,{"children":["$","title",null,{"children":"Test"}]}],["$","body",null,{"children":[["$","a",null,{"href":"/","children":"Go home"}]," | ",["$","a",null,{"href":"/about","children":"Go to about"}],["$","$1",null,{"children":["$","div",null,{"children":["$","h1",null,{"children":"Home"}]}]}]]}]]}]`]; */
  /* const mockPayload = ["0:["$","div",null,{"className":"foo"}]\n", "1:null\n"]; */
  /* const mockPayload = [`0:[null]\n`, `1:"$Sreact.suspense"\n`]; */
  /* <h1> {"Hello"} </h1> */
  /* window.srr_stream.push('0:I["$","div","0",{"children":[["$","h1","0",{"children":["Hellowww"]}]],"id":"root"}]'); */
  /* const mockPayload = [`0:["$","h1",null,{"children":["Hellowww"]}]\n`]; */
  /* const mockPayload = [`0:I["$","div","0",{"children":[["$","h1","0",{"children":["Hellowww"]}]],"id":"root"}]\n`]; */
  /* const mockPayload = [
    `0:I["$","div","0",{"children":[["$","div","0",{"children":[["$","div","0",{"children":["This is Light Server Component"]}],["$","div","0",{"children":[["$","div","0",{"children":[],"title":"Light Component"}]]}]]}],["$","div","0",{"children":["Heavy Server Component"]}]],"id":"root"}]\n`,
  ]; */

  /* const mockPayload = [
    `a:["$","div",null,{"children":["Sleep ",1,"s","$undefined"]}]\n`,
    `1:["$L7",["$","div",null,{"children":["Home Page",["$","$8",null,{"fallback":"Fallback 1","children":"$L9"}]]}],null]\n`,
    `9:["$","div",null,{"children":["Sleep ",1,"s",["$","$8",null,{"fallback":"Fallback 2","children":"$La"}]]}]\n`,
    `7:"$Sreact.suspense"\n`,
  ]; */
  /* const mockPayload = [
    `7:"$Sreact.suspense"\n`,
    `1:["$L7",["$","div",null,{"children":["Home Page",["$","$8",null,{"fallback":"Fallback 1","children":"$L9"}]]}],null]\n`,
    `9:["$","div",null,{"children":["Sleep ",1,"s",["$","$8",null,{"fallback":"Fallback 2","children":"$La"}]]}]\n`,
    `a:["$","div",null,{"children":["Sleep ",1,"s","$undefined"]}]\n`,
  ]; */
  /*  const rscPayload = [
     `7:"$Sreact.suspense"`,
     `1:["$L7",["$","div",null,{"children":["Home Page",["$","$8",null,{"fallback":"Fallback 1","children":"$L9"}]]}],null]`,
     `9:["$","div",null,{"children":["Sleep ",1,"s",["$","$8",null,{"fallback":"Fallback 2","children":"$La"}]]}]`,
     `a:["$","div",null,{"children":["Sleep ",1,"s","$undefined"]}]`
   ]; */

  const rscPayload = [
    /* `0:["$","div",null,{"children":["Hello"]}]`, */
    /* "0:[\"$\",\"div\",null,{\"children\":[[\"$\",\"span\",null,{\"children\":\"Home\"}],[\"$\",\"span\",null,{\"children\":\"Nohome\"}]]}]", */
    "1:I[\"./client-component.js\",[],\"Client_component\"]",
    "0:[[\"$\",\"span\",null,{\"children\":\"Hello!!!\"}],[\"$\",\"$1\",null,{}]]",
  ];

  /* let result = MyReactServerDOM.to_model (xxxxxxxxx) */
  /* load into file (result) */
  /* node debug-rsc.js (result) */
  /* cram test */

  /** @type {ReadableStream<Uint8Array>} */
  let mockReadableStream = new ReadableStream({
    start(stream) {
      const textEncoder = new TextEncoder();

      for (let chunk of rscPayload) {
        stream.enqueue(textEncoder.encode(chunk + '\n'));
      }
      stream.close();
    }
  });

  let debug = readableStream => {
    let reader = readableStream.getReader();
    let debugReader = ({ done, value }) => {
      if (done) {
        console.log("Stream complete");
        return;
      }
      console.log(value);
      return reader.read().then(debugReader);
    };
    reader.read().then(debugReader);
  };

  let promise = ReactServerDOM.createFromReadableStream(mockReadableStream);
  console.log(promise);

  window.__exported_components["./client-component.js"] = { Client_component: () => <div>Client</div> };

  React.startTransition(() => {
    let element = document.getElementById("root");
    root = ReactDOM.createRoot(element);
    root.render(<React.Suspense fallback={"LOADING?!?!?!?!"}>
      <Use promise={promise} />
    </React.Suspense>);
    /* root = ReactDOM.hydrateRoot(
      element,
      <React.Suspense fallback={"LOADING?!?!?!?!"}>
        <Use promise={promise} />
      </React.Suspense>
    ); */
  });

} catch (e) {
  console.error(e);
}

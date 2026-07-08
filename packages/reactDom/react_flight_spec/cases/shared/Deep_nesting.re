/* A 10-deep single-child chain: each level nests as the (non-array)
   "children" prop of its parent, all within the single root model row. */
let app = () =>
  <div className="level-1">
    <section>
      <article>
        <header>
          <nav>
            <ul>
              <li>
                <p> <span> <em> {React.string("bottom")} </em> </span> </p>
              </li>
            </ul>
          </nav>
        </header>
      </article>
    </section>
  </div>;

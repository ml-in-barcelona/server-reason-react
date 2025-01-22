import React from "react";

function Use({ promise }) {
	const tree = React.use(promise);
	return tree;
}
export default Use;

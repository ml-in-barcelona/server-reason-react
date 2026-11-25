type error = RouterSearchParse.error = QueryTooLong

let parse search = RouterSearchParse.parse ~text:Fun.id ~slice:RouterUrl.slice search


console.info("Dev tools Starting!", process.argv);

require("yalr")({
  path: ["scripts", "styles"],
  ignore: "*.styl"
});

require("grunt").tasks("watch");

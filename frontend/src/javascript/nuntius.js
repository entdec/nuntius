import "../style/nuntius.scss";

import { definitionsFromContext } from "stimulus/webpack-helpers";
import { Application } from "stimulus";
import "trix";
import "trix/dist/trix.css";

export class Nuntius {
  static start(application) {
    if(!application) {
      application = Application.start();
    }
    console.log("Nuntius");
    this.application = application;
    const context = require.context("./controllers", true, /\.js$/);
    this.application.load(definitionsFromContext(context));
  }
}

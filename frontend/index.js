import { definitionsFromContext } from "stimulus/webpack-helpers";
import { Application } from "stimulus";

export class Nuntius {
  static start(application) {
    if(!application) {
      application = Application.start();
    }
    console.log("Nuntius");
    this.application = application;
    const context = require.context("./javascript/controllers", true, /\.js$/);
    this.application.load(definitionsFromContext(context));
  }
}

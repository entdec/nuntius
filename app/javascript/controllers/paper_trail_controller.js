import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["diffContainer", "dialog"];


  toggle(event) {

    const button = event.currentTarget;
    const currentRow = button.closest("tr"); 
    const diffContainer = currentRow.nextElementSibling; 

    if (diffContainer) {
      diffContainer.classList.toggle("hidden");
    }
  }

  show(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const versionId = button.dataset.versionId; 
    const dialog = document.getElementById(`rollback-dialog-${versionId}`); 

    if (dialog) {
      dialog.classList.toggle("hidden");
    } else {
      console.error(`Dialog for version ${versionId} not found!`);
    }
  }




}

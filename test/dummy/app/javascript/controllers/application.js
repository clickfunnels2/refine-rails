import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

// Load refine-rails controllers
import { controllerDefinitions as refineControllers } from "@hammerstone/refine-rails"
application.load(refineControllers)

export { application }
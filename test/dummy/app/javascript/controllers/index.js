import { Application } from '@hotwired/stimulus'

const application = Application.start()

import HelloController from './controllers/hello_controller'
application.register('hello', HelloController)

// import { controllerDefinitions as refineControllers } from "@hammerstone/refine-rails"
// application.load(refineControllers)

window.Stimulus = application


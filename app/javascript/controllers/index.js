// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

import "./scrolltop_button"
import "./carousel_auto_scroll"
import "./one_at_a_time"
import "./video_plalyer"
import "./details_focus_scroll"
import "./gauge"
import "./scroll_gauges"

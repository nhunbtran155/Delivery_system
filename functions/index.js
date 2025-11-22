// ================================================================
// Firebase Cloud Functions Entry Point
// ================================================================

import * as logger from "firebase-functions/logger";

import { getDirections } from "./getDirections.js";
import { calculatePrice } from "./calculatePrice.js";

export const apiGetDirections = getDirections;
export const apiCalculatePrice = calculatePrice;

logger.info("Cloud Functions loaded.");

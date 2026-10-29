const userService = require('./user.service');

const ACTIVE = { status: 'active', tier: 'premium' };
// Cancelled still has Premium until expiresAt; the app asks RevenueCat, not this record.
const CANCELLED = { status: 'cancelled', tier: 'premium' };
const FREE = { status: 'free', tier: 'none' };

/** What each RevenueCat event does to the subscription. Others are acknowledged and ignored. */
const SUBSCRIPTION_BY_EVENT = {
  INITIAL_PURCHASE: ACTIVE,
  RENEWAL: ACTIVE,
  UNCANCELLATION: ACTIVE,
  SUBSCRIPTION_EXTENDED: ACTIVE,
  // Also sent for refunds, with expiration_at_ms set to when access ended.
  CANCELLATION: CANCELLED,
  EXPIRATION: FREE,
};

const toIso = (ms) => (Number.isFinite(ms) ? new Date(ms).toISOString() : undefined);

/**
 * The app logs in to RevenueCat with our user id, but an event can also name
 * the anonymous id used before sign-in; try every id it lists.
 */
const findUser = async (event) => {
  const ids = [event.app_user_id, event.original_app_user_id, ...(event.aliases || [])];
  for (const id of new Set(ids.filter((id) => typeof id === 'string' && id))) {
    const user = await userService.findById(id);
    if (user) return user;
  }
  return null;
};

/** Moves the purchase between accounts (e.g. restored while signed in as someone else). */
const applyTransfer = async (event) => {
  let applied = false;
  for (const [ids, subscription] of [
    [event.transferred_from, FREE],
    [event.transferred_to, ACTIVE],
  ]) {
    for (const id of ids || []) {
      if (await userService.updateSubscription(id, subscription)) applied = true;
    }
  }
  return applied;
};

/**
 * Applies one RevenueCat webhook event to the user's subscription record.
 * Returns whether a user was updated. Unknown users and event types are
 * ignored rather than rejected, so RevenueCat doesn't keep retrying them.
 */
const handleRevenueCatEvent = async (event) => {
  if (!event || typeof event.type !== 'string') return false;
  if (event.type === 'TRANSFER') return applyTransfer(event);

  const subscription = SUBSCRIPTION_BY_EVENT[event.type];
  if (!subscription) return false;

  const user = await findUser(event);
  if (!user) return false;

  const expiresAt = toIso(event.expiration_at_ms);
  await userService.updateSubscription(user.id, { ...subscription, ...(expiresAt && { expiresAt }) });
  return true;
};

module.exports = { handleRevenueCatEvent };

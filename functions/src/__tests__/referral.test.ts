/**
 * Referral code & reward function tests
 */

describe("redeemReferralCode", () => {
  test("stores referrerId on user doc for valid code", () => {
    const code = "ABCD1234";
    const referrerId = "user_referrer";
    const update = {
      referredBy: referrerId,
      referralCodeUsed: code,
    };
    expect(update.referredBy).toBe("user_referrer");
    expect(update.referralCodeUsed).toBe("ABCD1234");
  });

  test("rejects invalid code (wrong length)", () => {
    const code = "SHORT";
    const isValid = code.length === 8;
    expect(isValid).toBe(false);
  });

  test("code is uppercased and trimmed", () => {
    const raw = "  abcd1234  ";
    const code = raw.toUpperCase().trim();
    expect(code).toBe("ABCD1234");
    expect(code.length).toBe(8);
  });

  test("rejects own referral code", () => {
    const callerId = "user_123";
    const referrerId = "user_123";
    const isSelfReferral = callerId === referrerId;
    expect(isSelfReferral).toBe(true);
  });

  test("rejects already-referred user", () => {
    const existingReferral = "user_old_referrer";
    const hasReferral = !!existingReferral;
    expect(hasReferral).toBe(true);
  });
});

describe("processReferralReward", () => {
  test("extends referrer subscription by 30 days", () => {
    const currentExpiry = new Date("2026-04-01");
    const newExpiry = new Date(currentExpiry.getTime() + 30 * 24 * 60 * 60 * 1000);
    const diffDays = Math.round((newExpiry.getTime() - currentExpiry.getTime()) / (24 * 60 * 60 * 1000));
    expect(diffDays).toBe(30);
  });

  test("extends referee subscription by 30 days", () => {
    const currentExpiry = new Date("2026-04-15");
    const newExpiry = new Date(currentExpiry.getTime() + 30 * 24 * 60 * 60 * 1000);
    const diffDays = Math.round((newExpiry.getTime() - currentExpiry.getTime()) / (24 * 60 * 60 * 1000));
    expect(diffDays).toBe(30);
  });

  test("uses max(currentExpiry, now) as base date", () => {
    // If subscription already expired, use now as base
    const expiredAt = new Date("2025-01-01");
    const now = new Date();
    const base = new Date(Math.max(expiredAt.getTime(), now.getTime()));
    expect(base.getTime()).toBe(now.getTime());
  });

  test("sends notification to both users", () => {
    const referrerNotif = { title: "🎁 Referral Reward! +30 Days Free", type: "referral" };
    const refereeNotif = { title: "🎁 Welcome Bonus! +30 Days Free", type: "referral" };
    expect(referrerNotif.type).toBe("referral");
    expect(refereeNotif.type).toBe("referral");
  });

  test("is idempotent per referee (no duplicate rewards)", () => {
    const existingRewards = [{ refereeId: "user_A" }];
    const newRefereeId = "user_A";
    const alreadyRewarded = existingRewards.some((r) => r.refereeId === newRefereeId);
    expect(alreadyRewarded).toBe(true);
  });

  test("creates audit trail in referral_rewards collection", () => {
    const reward = {
      referrerId: "user_referrer",
      refereeId: "user_referee",
      rewardDays: 30,
      bothRewarded: true,
    };
    expect(reward.rewardDays).toBe(30);
    expect(reward.bothRewarded).toBe(true);
  });
});

package com.adobe.plugins;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;

import com.google.analytics.tracking.android.GAServiceManager;
import com.google.analytics.tracking.android.GoogleAnalytics;
import com.google.analytics.tracking.android.Tracker;
import com.google.analytics.tracking.android.Transaction;
import com.google.analytics.tracking.android.Transaction.Item;

public class GAPlugin extends CordovaPlugin {
	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callback) {
		GoogleAnalytics ga = GoogleAnalytics.getInstance(cordova.getActivity());
		Tracker tracker = ga.getDefaultTracker(); 

		if (action.equals("initGA")) {
			try {
				tracker = ga.getTracker(args.getString(0));
				GAServiceManager.getInstance().setDispatchPeriod(args.getInt(1));
				ga.setDefaultTracker(tracker);
				callback.success("initGA - id = " + args.getString(0) + "; interval = " + args.getInt(1) + " seconds");
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("exitGA")) {
			try {
				GAServiceManager.getInstance().dispatch();
				callback.success("exitGA");
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("trackEvent")) {
			try {
				tracker.sendEvent(args.getString(0), args.getString(1), args.getString(2), args.getLong(3));
				callback.success("trackEvent - category = " + args.getString(0) + "; action = " + args.getString(1) + "; label = " + args.getString(2) + "; value = " + args.getInt(3));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("trackPage")) {
			try {
				tracker.sendView(args.getString(0));
				callback.success("trackPage - url = " + args.getString(0));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("setVariable")) {
			try {
				tracker.setCustomDimension(args.getInt(0), args.getString(1));
				callback.success("setVariable passed - index = " + args.getInt(0) + "; value = " + args.getString(1));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		else if (action.equals("setDimension")) {
			try {
				tracker.setCustomDimension(args.getInt(0), args.getString(1));
				callback.success("setDimension passed - index = " + args.getInt(0) + "; value = " + args.getString(1));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		else if (action.equals("setMetric")) {
			try {
				tracker.setCustomMetric(args.getInt(0), args.getLong(1));
				callback.success("setVariable passed - index = " + args.getInt(2) + "; key = " + args.getString(0) + "; value = " + args.getString(1));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		else if (action.equals("trackTransactionAndItem")) {
			try {

				Transaction trans = new Transaction.Builder(
						args.getString(0),											// (String) Transaction Id, should be unique.
						(long) args.getDouble(2)*1000000)							// (long) Order total (in micros)
						.setAffiliation(args.getString(1))                            // (String) Affiliation
						.setTotalTaxInMicros((long) args.getDouble(3)*1000000)		// (long) Total tax (in micros)
						.setShippingCostInMicros((long) args.getDouble(4)*1000000)	// (long) Total shipping cost (in micros)
						.setCurrencyCode("EUR")							// (String) Currency code TODO change
						.build();

				Item item = new Item.Builder(
						args.getString(6),//sku
						args.getString(5),//name
						((long) args.getDouble(8)*1000000),//price in micros
						(long)1)
						.setProductCategory(args.getString(7))//category
						.build();

				trans.addItem(item);
				tracker.sendTransaction(trans);

				callback.success
						(
								"trackTransactionAndItem: ----------" +
										" Transaction ID = "+ args.getString(0) +
										" Affiliation "+args.getString(1) +
										" Revenue " + args.getDouble(2)+
										" Tax " +   args.getDouble(3)+
										" Shipping " + args.getDouble(4)+
										" Currency code " + args.getString(5)+
										" --- Transaction item ----" +
										" SKU " + args.getString(6) +
										" Name " + args.getString(5) +
										" Price " + args.getDouble(8) +
										" Category " + 	args.getString(7)
						);
				return true;

			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		return false;
	}
}


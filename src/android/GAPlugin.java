package com.adobe.plugins;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;

import com.google.android.gms.analytics.GoogleAnalytics;
import com.google.android.gms.analytics.Logger.LogLevel;
import com.google.android.gms.analytics.HitBuilders;
import com.google.android.gms.analytics.Tracker;

import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.util.HashMap;
import java.util.Map.Entry;
import java.util.Currency;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

public class GAPlugin extends CordovaPlugin {


	private static final String GA_TRACKING_ID = "UA-8374345-6";
	private static final int DISPATCH_PERIOD = 10;
	public HashMap<Integer, String> customDimensions = new HashMap<Integer, String>();
	public HashMap<Integer, Long> customMetrics = new HashMap<Integer, Long>();

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callback) {
		GoogleAnalytics ga = GoogleAnalytics.getInstance(cordova.getActivity());
		Tracker tracker = ga.newTracker(GA_TRACKING_ID);
		//enable exception reporting
		tracker.enableExceptionReporting(true);
		//anonymize IP
 		tracker.setAnonymizeIp(true);
		ga.setLocalDispatchPeriod(DISPATCH_PERIOD);

		if (action.equals("initGA")) {
			try {

				if(ga==null || tracker==null || !args.getString(0).equals(GA_TRACKING_ID) || args.getInt(1)!=DISPATCH_PERIOD) {
					ga = GoogleAnalytics.getInstance(cordova.getActivity());
					tracker = ga.newTracker(args.getString(0));
					ga.setLocalDispatchPeriod(args.getInt(1));
				}

				callback.success("initGA - id = " + args.getString(0) + "; interval = " + args.getInt(1) + " seconds");
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("exitGA")) {
			try {
				ga.dispatchLocalHits();
				callback.success("exitGA");
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("trackEvent")) {
			try {

				HitBuilders.EventBuilder hitBuilder = new HitBuilders.EventBuilder();
				addCustomDimensionsToHitBuilder(hitBuilder);
				addCustomMetricsToHitBuilder(hitBuilder);

				tracker.send(hitBuilder.setCategory(args.getString(0))
								.setAction(args.getString(1))
								.setLabel(args.getString(2))
								.setValue(args.getInt(3))
								.build()
				);

				callback.success("trackEvent - category = " + args.getString(0) + "; action = " + args.getString(1) + "; label = " + args.getString(2) + "; value = " + args.getInt(3));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("trackPage")) {
			try {

				HitBuilders.AppViewBuilder hitBuilder = new HitBuilders.AppViewBuilder();
				addCustomDimensionsToHitBuilder(hitBuilder);
				addCustomMetricsToHitBuilder(hitBuilder);

				tracker.setScreenName(args.getString(0));
				tracker.send(hitBuilder.build());

				callback.success("trackPage - url = " + args.getString(0));
				return true;

			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		} else if (action.equals("setVariable")) {
			try {
				customDimensions.put(args.getInt(0), args.getString(1));
				//tracker.setCustomDimension(args.getInt(0), args.getString(1));
				callback.success("setVariable passed - index = " + args.getInt(0) + "; value = " + args.getString(1));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		else if (action.equals("setDimension")) {
			try {
				customDimensions.put(args.getInt(0), args.getString(1));
				//tracker.setCustomDimension(args.getInt(0), args.getString(1));
				callback.success("setDimension passed - index = " + args.getInt(0) + "; value = " + args.getString(1));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		else if (action.equals("setMetric")) {//TODO
			try {
				customMetrics.put(args.getInt(0), args.getLong(1));
				//tracker.setCustomMetric(args.getInt(0), args.getLong(1));
				callback.success("setVariable passed - index = " + args.getInt(2) + "; key = " + args.getString(0) + "; value = " + args.getString(1));
				return true;
			} catch (final Exception e) {
				callback.error(e.getMessage());
			}
		}
		else if (action.equals("trackTransactionAndItem")) {
			try {

				final Logger LOG = Logger.getLogger("GAPlugin");
				LOG.log(Level.INFO, "trackTransactionAndItem");

				String currencyCode  = Currency.getInstance(Locale.getDefault()).getCurrencyCode();
				HitBuilders.TransactionBuilder hitBuilder = new HitBuilders.TransactionBuilder();
				addCustomDimensionsToHitBuilder(hitBuilder);
				addCustomMetricsToHitBuilder(hitBuilder);

				StringBuilder sb = new StringBuilder("Transaction Hit -> ").append("transactionId: ").append(args.getString(0)).append(", affiliation: ").append(args.getString(1))
						.append(", revenue: ").append(args.getDouble(2)).append(", tax: ").append(args.getDouble(3))
						.append(", shipping: ").append(args.getDouble(4)).append(", currencyCode: ").append(currencyCode);

				LOG.log(Level.INFO, sb.toString());

				tracker.send(hitBuilder
								.setTransactionId(args.getString(0))
								.setAffiliation(args.getString(1))
								.setRevenue((long) args.getDouble(2))
								.setTax((long) args.getDouble(3))
								.setShipping((long) args.getDouble(4))
								.setCurrencyCode(currencyCode)
								.build()
				);



				HitBuilders.ItemBuilder hitItemBuilder = new HitBuilders.ItemBuilder();
				addCustomDimensionsToHitBuilder(hitItemBuilder);
				addCustomMetricsToHitBuilder(hitItemBuilder);

				sb = new StringBuilder("Transaction Item Hit -> ").append("transactionId: ").append(args.getString(0))
						.append(", name: ").append(args.getString(5)).append(", SKU: ").append(args.getString(6))
						.append(", category: ").append(args.getString(7)).append(", price: ").append(args.getDouble(8))
						.append(", quantity: ").append(args.getLong(9)).append(", currencyCode: ").append(currencyCode);

				LOG.log(Level.INFO, sb.toString());

				tracker.send(hitItemBuilder
								.setTransactionId(args.getString(0))
								.setName(args.getString(5))
								.setSku(args.getString(6))
								.setCategory(args.getString(7))
								.setPrice((long) args.getDouble(8))
								.setQuantity(args.getLong(9))
								.setCurrencyCode(currencyCode)
								.build()
				);

				callback.success
						(
								"trackTransactionAndItem: ----------" +
										" Transaction ID = "+ args.getString(0) +
										" Affiliation "+args.getString(1) +
										" Revenue " + args.getDouble(2)+
										" Tax " +   args.getDouble(3)+
										" Shipping " + args.getDouble(4)+
										" Currency code " + currencyCode +
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

	private <T> void addCustomDimensionsToHitBuilder(T builder) {
		//unfortunately the base HitBuilders.HitBuilder class is not public, therefore have to use reflection to use
		//the common setCustomDimension (int index, String dimension) method
		try {
			Method builderMethod = builder.getClass().getMethod("setCustomDimension", Integer.TYPE, String.class);

			for (Entry<Integer, String> entry : customDimensions.entrySet()) {
				Integer key = entry.getKey();
				String value = entry.getValue();
				try {
					builderMethod.invoke(builder, (key), value);
				} catch (IllegalArgumentException e) {
				} catch (IllegalAccessException e) {
				} catch (InvocationTargetException e) {
				}
			}
		} catch (SecurityException e) {
		} catch (NoSuchMethodException e) {
		}
	}

	private <T> void addCustomMetricsToHitBuilder(T builder) {
		//unfortunately the base HitBuilders.HitBuilder class is not public, therefore have to use reflection to use
		//the common setCustomDimension (int index, String dimension) method
		try {
			Method builderMethod = builder.getClass().getMethod("setCustomMetric", Integer.TYPE, String.class);

			for (Entry<Integer, Long> entry : customMetrics.entrySet()) {
				Integer key = entry.getKey();
				Long value = entry.getValue();
				try {
					builderMethod.invoke(builder, (key), value);
				} catch (IllegalArgumentException e) {
				} catch (IllegalAccessException e) {
				} catch (InvocationTargetException e) {
				}
			}
		} catch (SecurityException e) {
		} catch (NoSuchMethodException e) {
		}
	}
}


// ===================================================================================================
//                           _  __     _ _
//                          | |/ /__ _| | |_ _  _ _ _ __ _
//                          | ' </ _` | |  _| || | '_/ _` |
//                          |_|\_\__,_|_|\__|\_,_|_| \__,_|
//
// This file is part of the Borhan Collaborative Media Suite which allows users
// to do with audio, video, and animation what Wiki platfroms allow them to do with
// text.
//
// Copyright (C) 2006-2011  Borhan Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// @ignore
// ===================================================================================================
package com.borhan.delegates {

	import com.borhan.config.IBorhanConfig;
	import com.borhan.config.BorhanConfig;
	import com.borhan.core.KClassFactory;
	import com.borhan.encryption.MD5;
	import com.borhan.errors.BorhanError;
	import com.borhan.events.BorhanEvent;
	import com.borhan.net.BorhanCall;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;

	public class WebDelegateBase extends EventDispatcher implements IBorhanCallDelegate {

		public static var CONNECT_TIME:int = 120000; //120 secs
		public static var LOAD_TIME:int = 120000; //120 secs

		protected var connectTimer:Timer;
		protected var loadTimer:Timer;

		protected var _call:BorhanCall;
		protected var _config:BorhanConfig;

		protected var loader:URLLoader;
		protected var fileRef:FileReference;


		//Setters & getters 
		public function get call():BorhanCall {
			return _call;
		}


		public function set call(newVal:BorhanCall):void {
			_call = newVal;
		}


		public function get config():IBorhanConfig {
			return _config;
		}


		public function set config(newVal:IBorhanConfig):void {
			_config = newVal as BorhanConfig;
		}


		public function WebDelegateBase(call:BorhanCall = null, config:BorhanConfig = null) {
			this.call = call;
			this.config = config;
			if (!call)
				return; //maybe a multi request
			if (call.useTimeout) {
				connectTimer = new Timer(CONNECT_TIME, 1);
				connectTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onConnectTimeout);

				loadTimer = new Timer(LOAD_TIME, 1);
				loadTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onLoadTimeOut);
			}
			execute();
		}


		public function close():void {
			try {
				loader.close();
			}
			catch (e:*) {
			}

			if (call.useTimeout) {
				connectTimer.stop();
				loadTimer.stop();
			}
		}


		protected function onConnectTimeout(event:TimerEvent):void {
			var kError:BorhanError = new BorhanError();
			kError.errorCode = "CONNECTION_TIMEOUT";
			kError.errorMsg = "Connection Timeout: " + CONNECT_TIME / 1000 + " sec with no post command from borhan client.";
			_call.handleError(kError);
			dispatchEvent(new BorhanEvent(BorhanEvent.FAILED, false, false, false, null, kError));

			loadTimer.stop();
			close();
		}


		protected function onLoadTimeOut(event:TimerEvent):void {
			connectTimer.stop();

			close();

			var kError:BorhanError = new BorhanError();
			kError.errorCode = "POST_TIMEOUT";
			kError.errorMsg = "Post Timeout: " + LOAD_TIME / 1000 + " sec with no post result.";
			_call.handleError(kError);
			dispatchEvent(new BorhanEvent(BorhanEvent.FAILED, false, false, false, null, kError));
		}


		protected function execute():void {
			if (call == null) {
				throw new Error('No call defined.');
			}
			post(); //post the call
		}


		/**
		* Helper function for sending the call straight to the server
		*/
		protected function post():void {

			addOptionalArguments();

			formatRequest();

			sendRequest();

			if (call.useTimeout) {
				connectTimer.start();
			}
		}


		protected function formatRequest():void {
			//The configuration is stronger then the args
			if (_config.partnerId != null && _call.args["partnerId"] == -1)
				_call.setRequestArgument("partnerId", _config.partnerId);

			if (_config.ks != null)
				_call.setRequestArgument("ks", _config.ks);

			if (_config.clientTag != null)
				_call.setRequestArgument("clientTag", _config.clientTag);

			_call.setRequestArgument("ignoreNull", _config.ignoreNull);

			//Create signature hash.
			//call.setRequestArgument("kalsig", getMD5Checksum(call));
		}


		protected function getMD5Checksum(call:BorhanCall):String {
			var props:Array = new Array();
			for each (var prop:String in call.args)
				props.push(prop);

			props.push("service");
			props.push("action");
			props.sort();

			var s:String;
			for each (prop in props) {
				s += prop;

				if (prop == "service")
					s += call.service;
				else if (prop == "action")
					s += call.action;
				else
					s += call.args[prop];
			}

			return MD5.encrypt(s);
		}


		protected function sendRequest():void {

			//construct the loader
			createURLLoader();

			//Create signature hash.
			var kalsig:String = getMD5Checksum(call);


			//create the service request for normal calls
			var url:String = _config.protocol + _config.domain + "/" + _config.srvUrl + "?service=" + call.service + "&action=" + call.action + "&kalsig=" + kalsig;;

			if (_call.method == URLRequestMethod.GET)
				url += "&";

			var req:URLRequest = new URLRequest(url);
			req.contentType = "application/x-www-form-urlencoded";
			req.method = call.method;
			req.data = call.args;

			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.load(req);
		}


		protected function createURLLoader():void {
			loader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onDataComplete);
			loader.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHTTPStatus);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			loader.addEventListener(Event.OPEN, onOpen);
		}


		protected function onHTTPStatus(event:HTTPStatusEvent):void {
		}


		protected function onOpen(event:Event):void {
			if (call.useTimeout) {
				connectTimer.stop();
				loadTimer.start();
			}
		}


		protected function addOptionalArguments():void {
			//add optional args here
		}


		// Event Handlers
		
		/**
		 * try to process received data. 
		 * if procesing failed, let call handle the processing error
		 * @param event load complete event
		 */
		protected function onDataComplete(event:Event):void {
			try {
				handleResult(XML(event.target.data));
			}
			catch (e:Error) {
				var kErr:BorhanError = new BorhanError();
				kErr.errorCode = String(e.errorID);
				kErr.errorMsg = e.message;
				_call.handleError(kErr);
			}
		}


		/**
		 * handle io or security error events from the loader.
		 * create relevant BorhanError, let the call process it. 
		 * @param event
		 */
		protected function onError(event:ErrorEvent):void {
			clean();
			var kError:BorhanError = createBorhanError(event, loader.data);

			if (!kError) {
				kError = new BorhanError();
				kError.errorMsg = event.text;
				kError.errorCode = event.type; 	// either IOErrorEvent.IO_ERROR or SecurityErrorEvent.SECURITY_ERROR
			}

			call.handleError(kError);

			dispatchEvent(new BorhanEvent(BorhanEvent.FAILED, false, false, false, null, kError));
		}


		/**
		 * parse the server's response and let the call process it.
		 * @param result  server's response
		 */
		protected function handleResult(result:XML):void {
			clean();

			var error:BorhanError = validateBorhanResponse(result);

			if (error == null) {
				var digestedResult:Object = parse(result);
				call.handleResult(digestedResult);
			}
			else {
				call.handleError(error);
			}
		}


		/**
		* stop timers and clean event listeners
		 */
		protected function clean():void {
			if (call.useTimeout) {
				connectTimer.stop();
				loadTimer.stop();
			}

			if (loader == null) {
				return;
			}

			loader.removeEventListener(Event.COMPLETE, onDataComplete);
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			loader.removeEventListener(Event.OPEN, onOpen);
		}


		/**
		* create the correct object and populate it with the given values. if the needed class is not found
		 * in the file, a generic object is created with attributes matching the XML attributes.
		* Override this parssing function in the specific delegate to create the correct object.
		* @param   result      instance attributes
		* @return an instance of the class declared by the given XML.
		* */
		public function parse(result:XML):* {
			//by defualt create the response object
			var cls:Class;
			try {
				cls = getDefinitionByName('com.borhan.vo.' + result.result.objectType) as Class;
			}
			catch (e:Error) {
				cls = Object;
			}
			var obj:* = (new KClassFactory(cls)).newInstanceFromXML(result.result);
			return obj;
		}


		/**
		 * If the result string holds an error, return a BorhanError object with
		 * relevant values. <br/>
		 * Overide this to create validation object and fill it.
		 * @param result  the string returned from the server.
		 * @return  matching error object
		 */
		protected function validateBorhanResponse(result:String):BorhanError {
			var kError:BorhanError = null;
			var xml:XML = XML(result);
			if (xml.result.hasOwnProperty('error') 
				&& xml.result.error.hasOwnProperty('code')
				&& xml.result.error.hasOwnProperty('message')) {
				
				kError = new BorhanError();
				kError.errorCode = String(xml.result.error.code);
				kError.errorMsg = xml.result.error.message;
				dispatchEvent(new BorhanEvent(BorhanEvent.FAILED, false, false, false, null, kError));
			}

			return kError;
		}


		/**
		 * create error object and fill it with relevant details
		 * @param event
		 * @param loaderData
		 * @return detailed BorhanError to be processed
		 */
		protected function createBorhanError(event:ErrorEvent, loaderData:*):BorhanError {
			var ke:BorhanError = new BorhanError();
			ke.errorMsg = event.text;
			ke.errorCode = event.type;
			return ke;
		}


		/**
		* create the url that is used for serve actions
		* @param call    the BorhanCall that defines the required parameters
		 * @return URLRequest with relevant parameters
		* */
		public function getServeUrl(call:BorhanCall):URLRequest {
			var url:String = _config.protocol + _config.domain + "/" + _config.srvUrl + "?service=" + call.service + "&action=" + call.action;
			for (var key:String in call.args) {
				url += "&" + key + "=" + call.args[key];
			}
			var req:URLRequest = new URLRequest(url);
			req.contentType = "application/x-www-form-urlencoded";
			req.method = call.method;
//          req.data = call.args; 
			return req;
		}

	}
}

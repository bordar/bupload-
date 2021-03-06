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
package com.borhan.vo
{
	import com.borhan.vo.BorhanMediaEntry;

	[Bindable]
	public dynamic class BorhanLiveStreamEntry extends BorhanMediaEntry
	{
		/**
		 * The message to be presented when the stream is offline
		 * 
		 **/
		public var offlineMessage : String = null;

		/**
		 * The stream id as provided by the provider
		 * 
		 **/
		public var streamRemoteId : String = null;

		/**
		 * The backup stream id as provided by the provider
		 * 
		 **/
		public var streamRemoteBackupId : String = null;

		/**
		 * Array of supported bitrates
		 * 
		 **/
		public var bitrates : Array = null;

		/**
		 **/
		public var primaryBroadcastingUrl : String = null;

		/**
		 **/
		public var secondaryBroadcastingUrl : String = null;

		/**
		 **/
		public var streamName : String = null;

		/**
		 * The stream url
		 * 
		 **/
		public var streamUrl : String = null;

		/**
		 * HLS URL - URL for live stream playback on mobile device
		 * 
		 **/
		public var hlsStreamUrl : String = null;

		/**
		 * DVR Status Enabled/Disabled
		 * 
		 * @see com.borhan.types.BorhanDVRStatus
		 **/
		public var dvrStatus : int = int.MIN_VALUE;

		/**
		 * Window of time which the DVR allows for backwards scrubbing (in minutes)
		 * 
		 **/
		public var dvrWindow : int = int.MIN_VALUE;

		/**
		 * URL Manager to handle the live stream URL (for instance, add token)
		 * 
		 **/
		public var urlManager : String = null;

		/**
		 * Array of key value protocol->live stream url objects
		 * 
		 **/
		public var liveStreamConfigurations : Array = null;

		override public function getUpdateableParamKeys():Array
		{
			var arr : Array;
			arr = super.getUpdateableParamKeys();
			arr.push('offlineMessage');
			arr.push('bitrates');
			arr.push('primaryBroadcastingUrl');
			arr.push('secondaryBroadcastingUrl');
			arr.push('streamName');
			arr.push('streamUrl');
			arr.push('hlsStreamUrl');
			arr.push('urlManager');
			arr.push('liveStreamConfigurations');
			return arr;
		}

		override public function getInsertableParamKeys():Array
		{
			var arr : Array;
			arr = super.getInsertableParamKeys();
			arr.push('dvrStatus');
			arr.push('dvrWindow');
			return arr;
		}
	}
}

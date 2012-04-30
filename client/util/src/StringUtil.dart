/* StringUtil.dart

	String utilities.

	Design Note: we don't make them global functions to avoid name pollution.
	History:
		Sun Jan 15 11:04:13 TST 2012, Created by tomyeh

Copyright (C) 2012 Potix Corporation. All Rights Reserved.
*/

/** String utilities.
 */
class StringUtil {
	/** Add the given offset to each character of the given string.
	 */
	static String addCharCodes(String src, int diff) {
		int j = src.length;
		final List<int> dst = new List(j);
		while (--j >= 0)
			dst[j] = src.charCodeAt(j) + diff;
		return new String.fromCharCodes(dst);
	}

	/**
	 * Returns whether the character is according to its opts.
	 * @param char cc the character
	 * @param Map opts the options.
	<table border="1" cellspacing="0" width="100%">
	<caption> Allowed Options
	</caption>
	<tr>
	<th> Name
	</th><th> Allowed Values
	</th><th> Description
	</th></tr>
	<tr>
	<td> digit
	</td><td> true, false
	</td><td> Specifies the character is digit only.
	</td></tr>
	<tr>
	<td> upper
	</td><td> true, false
	</td><td> Specifies the character is upper case only.
	</td></tr>
	<tr>
	<td> lower
	</td><td> true, false
	</td><td> Specifies the character is lower case only.
	</td></tr>
	<tr>
	<td> whitespace
	</td><td> true, false
	</td><td> Specifies the character is whitespace only.
	</td></tr>
	<tr>
	<td> opts[cc]
	</td><td> true, false
	</td><td> Specifies the character is allowed only.
	</td></tr>
	</table>
	 * @return boolean
	 */
	static bool isChar(String cc, [bool digit=false, bool upper=false, bool lower=false,
	bool whitespace=false, String match=null]) {
		//TODO: remove them if Dart supports non-constant final
		if (_CC_0 == null) {
			_CC_0 = '0'.charCodeAt(0); _CC_9 = _CC_0 + 9;
			_CC_A = 'A'.charCodeAt(0); _CC_Z = _CC_A + 25;
			_CC_a = 'a'.charCodeAt(0); _CC_z = _CC_a + 25;
		}

		int v = cc.isEmpty() ? 0: cc.charCodeAt(0);
		return (digit && v >= _CC_0 && v <= _CC_9)
		|| (upper && v >= _CC_A && v <= _CC_Z)
		|| (lower && v >= _CC_a && v <= _CC_z)
		|| (whitespace && (cc == ' ' || cc == '\t' || cc == '\n' || cc == '\r'))
		|| (match != null && match.indexOf(cc) >= 0);
	}
	/** TODO: use intializer below when Dart supports non-constant final
	final int _CC_0 = '0'.charCodeAt(0), _CC_9 = _CC_0 + 9,
		_CC_A = 'A'.charCodeAt(0), _CC_Z = _CC_A + 25,
		_CC_a = 'a'.charCodeAt(0), _CC_z = _CC_a + 25;*/
	static int _CC_0, _CC_9, _CC_A, _CC_Z, _CC_a, _CC_z;

	static final Map<String, String>
		_decs = const {'lt': '<', 'gt': '>', 'amp': '&', 'quot': '"'},
		_encs = const {'<': 'lt', '>': 'gt', '&': 'amp', '"': 'quot'};

	/** Encodes the string to a valid XML string.
	 * @param String txt the text to encode
	 * @param Map opts [optional] the options. Allowd value:
	 * <ul>
	 * <li>pre - whether to replace whitespace with &amp;nbsp;</li>
	 * <li>multiline - whether to replace linefeed with &lt;br/&gt;</li>
	 * <li>maxlength - the maximal allowed length of the text</li>
	 * </ul>
	 * @return String the encoded text.
	 */
	static String encodeXML(String txt,
	[bool multiline=false, int maxlength=0, bool pre=false]) {
		if (txt == null) return null; //as it is

		int tl = txt.length;
		multiline = pre || multiline;

		if (!multiline && maxlength > 0 && tl > maxlength) {
			int j = maxlength;
			while (j > 0 && isChar(txt[j - 1], whitespace: true))
				--j;
			return encodeXML(txt.substring(0, j) + '...', pre:pre, multiline:multiline);
		}

		final StringBuffer out = new StringBuffer();
		int k = 0;
		String enc;
		if (multiline || pre) {
			for (int j = 0; j < tl; ++j) {
				String cc = txt[j];
				if ((enc = _encs[cc]) != null){
					out.add(txt.substring(k, j))
						.add('&').add(enc).add(';');
					k = j + 1;
				} else if (multiline && cc == '\n') {
					out.add(txt.substring(k, j)).add("<br/>\n");
					k = j + 1;
				} else if (pre && (cc == ' ' || cc == '\t')) {
					out.add(txt.substring(k, j)).add("&nbsp;");
					if (cc == '\t')
						out.add("&nbsp;&nbsp;&nbsp;");
					k = j + 1;
				}
			}
		} else {
			for (int j = 0; j < tl; ++j) {
				if ((enc = _encs[txt[j]]) != null) {
					out.add(txt.substring(k, j))
						.add('&').add(enc).add(';');
					k = j + 1;
				}
			}
		}

		if (k == 0) return txt;
		if (k < tl)
			out.add(txt.substring(k));
		return out.toString();
	}

	/** Decodes the XML string into a normal string.
	 * For example, &amp;lt; is convert to &lt;
	 * @param String txt the text to decode
	 * @return String the decoded string
	 */
	static String decodeXML(String txt) {
		if (txt == null) return null; //as it is

		final StringBuffer out = new StringBuffer();
		int k = 0, tl = txt.length;
		for (int j = 0; j < tl; ++j) {
			if (txt[j] == '&') {
				int l = txt.indexOf(';', j + 1);
				if (l >= 0) {
					String dec = txt[j + 1] == '#' ?
						new String.fromCharCodes(
							[/*TODO: wait until Dart support Hexadecimal parsing
								txt[j + 2].toLowerCase() == 'x' ?
								Math.parseInt(txt.substring(j + 3, l), 16):*/
								Math.parseInt(txt.substring(j + 2, l))]):
						_decs[txt.substring(j + 1, l)];
					if (dec != null) {
						out.add(txt.substring(k, j)).add(dec);
						k = (j = l) + 1;
					}
				}
			}
		}
		return k == 0 ? txt:
			k < tl ? out.add(txt.substring(k)).toString(): out.toString();
	}

	/** Encodes an integer to a string consisting of alpanumeric characters
	 * and underscore. With a prefix, it can be used as an identifier.
	 */
	static String encodeId(int v, [String prefix]) {
		final StringBuffer sb = new StringBuffer();
		if (prefix !== null)
			sb.add(prefix);

		do {
			int v2 = v % 37;
			if (v2 <= 9) sb.add(addCharCodes('0', v2));
			else sb.add(v2 == 36 ? '_': addCharCodes('a', v2 - 10));
		} while ((v ~/= 37) >= 1);
		return sb.toString();
	}

	/** Convert a number to a string appended with "px".
	 * Notice that it returns an empty string if val is null.
	 */
	static String px(num val) {
		return val !== null ? "${val}px": "";
	}
}
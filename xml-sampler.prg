*
* XMLSampler
*
* Create an XML sample document based on an XML Schema
*
* Wrapper to two transformation stylesheets that work in tandem: the first inserts required namespaces in second,
*  the actual sample generator
*
* Usage:
*  m.Sampler = CREATEOBJECT("XMLSampler")
*  m.Sampler.SetOption("Option", "Setting")
*  ? m.Sampler.SampleXSD("someSchema.xsd")
*

* install itself
IF !SYS(16) $ SET("Procedure")
	SET PROCEDURE TO (SYS(16)) ADDITIVE
ENDIF

#DEFINE SAFETHIS			ASSERT !USED("This") AND TYPE("This") == "O"

DEFINE CLASS XMLSampler AS Custom

	ADD OBJECT Options AS Collection

	SamplerXSL = ""
	SamplerNamespacesXSL = ""

	* the initialization loads the two transformation stylesheets, to be used later
	FUNCTION Init

		SAFETHIS

		TRY
			This.SamplerXSL = LOCFILE("sampler-xml-generator.xsl")
			This.SamplerNamespacesXSL = STRTRAN(FILETOSTR(LOCFILE("sampler-namespaces.xsl")), "sampler-xml-generator.xsl", This.SamplerXSL)
		CATCH
		ENDTRY

		RETURN !EMPTY(This.SamplerXSL) AND !EMPTY(This.SamplerNamespacesXSL)

	ENDFUNC

	* SetOption
	* Set a transformation option. See sampler-xml-generator.xsl for more details and available options
	PROCEDURE SetOption (Option AS String, Setting AS String)

		ASSERT TYPE("m.Option") + TYPE("m.Setting") == "CC" ;
			MESSAGE "String parameters expected."

		LOCAL SafeSetting AS String
		LOCAL ARRAY SettingBuffer[1]

		IF This.Options.GetKey(m.Option) != 0
			This.Options.Remove(m.Option)
		ENDIF

		ALINES(m.SettingBuffer, m.Setting)
		m.SafeSetting = EVL(m.SettingBuffer[1], "")

		This.Options.Add(m.SafeSetting, m.Option)

	ENDPROC

	* GetOption
	* Get the current status of a set transformation option (empty values may denote that the option was not set by a SetOption() call).
	FUNCTION GetOption (Option AS String) AS String

		ASSERT TYPE("m.Option") == "C" ;
			MESSAGE "String parameter expected."

		RETURN IIF(This.Options.GetKey(m.Option) != 0, This.Options(m.Option), "")

	ENDFUNC

	* SampleXSD
	* Generate an XML document based on an XML Schema
	* Returns an XML document source
	FUNCTION SampleXSD (XSDSource AS URLorDOMorString) AS String

		SAFETHIS

		LOCAL SamplerXSL AS String
		LOCAL OptionIndex AS Integer
		LOCAL XSLTParam AS String
		LOCAL XSLTChange AS String
		LOCAL Setting AS String
		LOCAL XSD AS MSXML2.DOMDocument60
		LOCAL XSLT AS MSXML2.DOMDocument60

		LOCAL SampleXML AS String

		* the final result
		m.SampleXML = ""

		m.XSD = CREATEOBJECT("MSXML2.DOMDocument.6.0")
		m.XSD.async = .F.

		* load the schema
		IF m.XSD.load(m.XSDSource) OR m.XSD.loadXML(m.XSDSource)

			* prepare the transformers
			m.XSLT = CREATEOBJECT("MSXML2.DOMDocument.6.0")
			m.XSLT.async = .F.

			* load the first step: to retrieve the schema namespaces and insert them in the sampler stylesheet
			IF m.XSLT.loadXML(This.SamplerNamespacesXSL)

				m.XSLT.setProperty("AllowDocumentFunction", .T.)

				* after this step going fine, we have a new version of the sampler adjusted to the schema namespaces
				* if some nodes require qualification, identified by prefixes, they are now part of the stylesheet namespaces list
				m.SamplerXSL = m.XSD.transformNode(m.XSLT)

				* pass all options set by SetOption() method
				FOR m.OptionIndex = 1 TO This.Options.Count

					* properly encode the setting
					m.Setting = This.Options.Item(m.OptionIndex)
					m.Setting = STRCONV(STRCONV(STRTRAN(STRTRAN(STRTRAN(m.Setting, "&", "&" + "amp;"), "<", "&" + "lt;"), ">", "&" + "gt;"), 1), 9)

					m.XSLTParam = '<xsl:param name="sample' + This.Options.GetKey(m.OptionIndex) + '">'
					m.XSLTChange = STREXTRACT(m.SamplerXSL, m.XSLTParam, "</xsl:param>", 1, 4)
					m.SamplerXSL = STRTRAN(m.SamplerXSL, m.XSLTChange, m.XSLTParam + m.Setting + "</xsl:param>")

				ENDFOR

				* now, load the second step: the real producer of the sampler
				IF m.XSLT.loadXML(m.SamplerXSL)
					* and try to create the sample
					m.SampleXML = m.XSD.transformNode(m.XSLT)
				ENDIF
			ENDIF
		ENDIF

		* whatever was produced...
		RETURN m.SampleXML

	ENDFUNC

ENDDEFINE

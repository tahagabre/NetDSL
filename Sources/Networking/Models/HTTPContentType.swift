public enum HTTPContentType: Sendable {
	case json
	case png
	case jpeg
	case pdf
	case xls
	case xlsx
	case ppt
	case pptx
	case doc
	case docx
	
	var value: String {
		return switch self {
		case .json: 
			"application/json"
		case .jpeg: 
			"image/jpeg"
		case .png: 
			"image/png"
		case .pdf: 
			"application/pdf"
		case .xls:
			"application/vnd.ms-excel"
		case .ppt:
			"application/vnd.ms-powerpoint"
		case .doc:
			"application/msword"
		case .xlsx:
			"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
		case .pptx:
			"application/vnd.openxmlformats-officedocument.presentationml.presentation"
		case .docx:
			"application/vnd.openxmlformats-officedocument.wordprocessingml.document"
		}
	}
}

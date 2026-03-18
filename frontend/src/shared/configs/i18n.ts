import i18n from "i18next";
import LanguageDetector from "i18next-browser-languagedetector";
import { initReactI18next } from "react-i18next";
import { KO_MESSAGES } from "../locales/ko/messages";

// 리소스 정의
const resources = {
	ko: {
		translation: KO_MESSAGES,
	},
} as const;

i18n
	.use(LanguageDetector) // 브라우저 언어 감지
	.use(initReactI18next) // react-i18next 연결
	.init({
		resources,
		lng: "ko", // 기본 언어
		fallbackLng: "ko",
		ns: ["translation"],
		defaultNS: "translation",
		interpolation: {
			escapeValue: false, // React는 이미 XSS 방어 기능을 포함하고 있음
		},
		react: {
			useSuspense: false,
		},
	});

export default i18n;

// 1. props에 들어갈 수 있는 값의 타입
export type PropValue = string | number | boolean | null | undefined;

// 2. 코드 그룹 인터페이스
export interface CodeGroup {
  group_code: string;
  group_name: string;
  description?: string;
  is_system: boolean;
  is_active: boolean;
  created_at?: string;
}

// 3. 상세 코드 인터페이스 (에러가 난 부분!)
// 기본값(Default)을 'Record<string, PropValue>'로 설정
export interface CodeDetail<T = Record<string, PropValue>> {
  group_code: string;
  detail_code: string;
  detail_name: string;
  sort_order: number;
  is_active: boolean;
  props?: T;
}

// 3. 상세 코드 인터페이스
// 제네릭 <T> 추가 및 기본값 설정
// export interface CodeDetail<T = Record<string, unknown>> {
//   group_code: string;
//   detail_code: string;
//   detail_name: string;
//   sort_order: number;
//   is_active: boolean;
//   props?: T; // any 제거 완료
// }

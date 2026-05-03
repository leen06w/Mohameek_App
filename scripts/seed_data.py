import firebase_admin
from firebase_admin import credentials, firestore

# الربط بملف المفتاح الخاص بك
cred = credentials.Certificate('scripts/muhamah-app-firebase-adminsdk-fbsvc-24f69b6408.json')
if not firebase_admin._apps:
    firebase_admin.initialize_app(cred)

db = firestore.client()

def seed_user_dashboard():
    # 1. إضافة بيانات المستخدم الأساسية (لتجربة تسجيل الدخول)
    user_data = {
        "uid": "user_test_01",
        "name": "لين وليد",
        "email": "leen@example.com",
        "role": "user",
        "createdAt": firestore.SERVER_TIMESTAMP
    }
    db.collection('users').document('user_test_01').set(user_data)
    print("✅ تم إنشاء حساب مستخدم تجريبي")

    # 2. إضافة إحصائيات للمستخدم (للعرض في الواجهة)
    stats = {
        "activeRequests": 2,
        "completedCases": 5,
        "totalPayments": "1200 SAR"
    }
    db.collection('users').document('user_test_01').collection('stats').document('overview').set(stats)

    # 3. إضافة طلبات (Requests) حالية تظهر في قائمة User Dashboard
    requests = [
        {
            "title": "استشارة تجارية",
            "lawyerName": "أحمد المحمد",
            "status": "قيد المراجعة",
            "date": "2026-04-21",
            "userId": "user_test_01"
        },
        {
            "title": "قضية عمالية",
            "lawyerName": "هبة",
            "status": "مكتملة",
            "date": "2026-04-15",
            "userId": "user_test_01"
        }
    ]
    
    for req in requests:
        db.collection('requests').add(req)
    
    print("✅ تم إنشاء طلبات تجريبية تظهر في لوحة المستخدم")

if __name__ == "__main__":
    seed_user_dashboard()
    print("🚀 البيانات الآن في Firebase! يمكنك الآن ربط Flutter لعرضها.")
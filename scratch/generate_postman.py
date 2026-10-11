import json
import os

collection = {
    "info": {
        "_postman_id": "38a926f8-71cc-4c16-be34-6ae66bedc76b",
        "name": "Flood Rescue Coordination & Relief Management System API",
        "description": "Postman Collection đầy đủ các REST API cho Dự án Hệ Thống Điều Phối Cứu Hộ & Quản Lý Cứu Trợ Lũ Lụt (FRS).",
        "schema": "https://schema.getpostman.com/json/collection/v2.1.0/collection.json"
    },
    "auth": {
        "type": "bearer",
        "bearer": [
            {
                "key": "token",
                "value": "{{token}}",
                "type": "string"
            }
        ]
    },
    "item": [
        {
            "name": "1. Authentication (Xác thực)",
            "item": [
                {
                    "name": "POST Login (Đăng nhập)",
                    "event": [
                        {
                            "listen": "test",
                            "script": {
                                "exec": [
                                    "if (pm.response.code === 200) {",
                                    "    var jsonData = pm.response.json();",
                                    "    if (jsonData.token) {",
                                    "        pm.environment.set(\"token\", jsonData.token);",
                                    "        console.log(\"Token auto-saved to environment:\", jsonData.token);",
                                    "    }",
                                    "}"
                                ],
                                "type": "text/javascript"
                            }
                        }
                    ],
                    "request": {
                        "auth": {
                            "type": "noauth"
                        },
                        "method": "POST",
                        "header": [
                            {
                                "key": "Content-Type",
                                "value": "application/json"
                            }
                        ],
                        "body": {
                            "mode": "raw",
                            "raw": json.dumps({
                                "email": "admin@rescue.vn",
                                "password": "admin123"
                            }, indent=2)
                        },
                        "url": {
                            "raw": "{{base_url}}/api/auth/login",
                            "host": ["{{base_url}}"],
                            "path": ["api", "auth", "login"]
                        },
                        "description": "Đăng nhập hệ thống bằng tài khoản Admin, Coordinator hoặc Staff để nhận JWT Bearer Token."
                    },
                    "response": []
                }
            ]
        },
        {
            "name": "2. Rescue Requests (Yêu cầu SOS & Cứu hộ)",
            "item": [
                {
                    "name": "POST Create Rescue Request (Gửi SOS Khẩn Cấp)",
                    "request": {
                        "method": "POST",
                        "header": [
                            {
                                "key": "Content-Type",
                                "value": "application/json"
                            }
                        ],
                        "body": {
                            "mode": "raw",
                            "raw": json.dumps({
                                "citizenName": "Nguyễn Văn An",
                                "phoneNumber": "0987654321",
                                "address": "123 Đường Lê Lợi, Phường Bến Thành, Quận 1, TP.HCM",
                                "latitude": 10.77688,
                                "longitude": 106.7008,
                                "urgencyLevel": "HIGH",
                                "description": "Gia đình có 4 người mắc kẹt trên mái nhà do nước dâng cao 2m",
                                "peopleCount": 4
                            }, indent=2)
                        },
                        "url": {
                            "raw": "{{base_url}}/api/v1/rescue-requests",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "rescue-requests"]
                        },
                        "description": "Người dân gửi yêu cầu SOS khẩn cấp kèm tọa độ GPS và thông tin mô tả."
                    },
                    "response": []
                },
                {
                    "name": "GET All Rescue Requests (Danh sách yêu cầu SOS)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/rescue-requests",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "rescue-requests"]
                        },
                        "description": "Lấy toàn bộ danh sách yêu cầu cứu hộ trên hệ thống."
                    },
                    "response": []
                },
                {
                    "name": "GET Rescue Request Stats (Thống kê SOS)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/rescue-requests/stats",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "rescue-requests", "stats"]
                        },
                        "description": "Lấy số liệu thống kê yêu cầu cứu hộ theo trạng thái."
                    },
                    "response": []
                },
                {
                    "name": "GET Track Rescue Request (Theo dõi SOS theo ID)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/rescue-requests/track/:id",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "rescue-requests", "track", ":id"],
                            "variable": [
                                {
                                    "key": "id",
                                    "value": "REQ123456",
                                    "description": "Mã ID yêu cầu SOS"
                                }
                            ]
                        },
                        "description": "Người dân tra cứu tiến độ xử lý của yêu cầu cứu hộ."
                    },
                    "response": []
                },
                {
                    "name": "PATCH Update Request Status (Cập nhật trạng thái SOS)",
                    "request": {
                        "method": "PATCH",
                        "header": [
                            {
                                "key": "Content-Type",
                                "value": "application/json"
                            }
                        ],
                        "body": {
                            "mode": "raw",
                            "raw": json.dumps({
                                "status": "IN_PROGRESS",
                                "note": "Đội cứu hộ số 1 đang di chuyển đến vị trí"
                            }, indent=2)
                        },
                        "url": {
                            "raw": "{{base_url}}/api/v1/rescue-requests/:id/status",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "rescue-requests", ":id", "status"],
                            "variable": [
                                {
                                    "key": "id",
                                    "value": "REQ123456"
                                }
                            ]
                        },
                        "description": "Điều phối viên cập nhật trạng thái yêu cầu SOS."
                    },
                    "response": []
                },
                {
                    "name": "POST Confirm Safety (Xác nhận an toàn)",
                    "request": {
                        "method": "POST",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/rescue-requests/:id/confirm-safety",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "rescue-requests", ":id", "confirm-safety"],
                            "variable": [
                                {
                                    "key": "id",
                                    "value": "REQ123456"
                                }
                            ]
                        },
                        "description": "Người dân hoặc điều phối viên xác nhận người dân đã an toàn."
                    },
                    "response": []
                }
            ]
        },
        {
            "name": "3. Rescue Teams & Coordination (Đội cứu hộ & Điều phối)",
            "item": [
                {
                    "name": "GET All Teams (Danh sách các đội cứu hộ)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/teams",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "teams"]
                        },
                        "description": "Lấy danh sách tất cả các đội cứu hộ."
                    },
                    "response": []
                },
                {
                    "name": "GET Available Teams (Danh sách đội sẵn sàng)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/teams/available",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "teams", "available"]
                        },
                        "description": "Lấy danh sách đội cứu hộ đang trong trạng thái sẵn sàng làm nhiệm vụ."
                    },
                    "response": []
                },
                {
                    "name": "GET Team Details (Chi tiết đội cứu hộ)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/teams/:id",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "teams", ":id"],
                            "variable": [
                                {
                                    "key": "id",
                                    "value": "TEAM_001"
                                }
                            ]
                        }
                    },
                    "response": []
                },
                {
                    "name": "PUT Update Team Info (Cập nhật thông tin đội)",
                    "request": {
                        "method": "PUT",
                        "header": [
                            {
                                "key": "Content-Type",
                                "value": "application/json"
                            }
                        ],
                        "body": {
                            "mode": "raw",
                            "raw": json.dumps({
                                "teamName": "Đội Cứu Hộ Số 1 - Phản Ứng Nhanh"
                            }, indent=2)
                        },
                        "url": {
                            "raw": "{{base_url}}/api/v1/teams/:id",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "teams", ":id"],
                            "variable": [
                                {
                                    "key": "id",
                                    "value": "TEAM_001"
                                }
                            ]
                        }
                    },
                    "response": []
                }
            ]
        },
        {
            "name": "4. Warehouses & Relief (Kho bãi & Nhu yếu phẩm)",
            "item": [
                {
                    "name": "GET All Warehouses (Danh sách kho bãi)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/warehouses",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "warehouses"]
                        }
                    },
                    "response": []
                },
                {
                    "name": "POST Create Warehouse (Tạo kho mới)",
                    "request": {
                        "method": "POST",
                        "header": [
                            {
                                "key": "Content-Type",
                                "value": "application/json"
                            }
                        ],
                        "body": {
                            "mode": "raw",
                            "raw": json.dumps({
                                "name": "Kho Cứu Trợ Trung Tâm 1",
                                "location": "Phường Thuận Phước, Quận Hải Châu, Đà Nẵng",
                                "capacity": 100000.0,
                                "managerId": "manager123"
                            }, indent=2)
                        },
                        "url": {
                            "raw": "{{base_url}}/api/v1/warehouses",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "warehouses"]
                        }
                    },
                    "response": []
                },
                {
                    "name": "GET Warehouse By Manager (Lấy kho theo Manager ID)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/warehouses/manager/:managerId",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "warehouses", "manager", ":managerId"],
                            "variable": [
                                {
                                    "key": "managerId",
                                    "value": "manager123"
                                }
                            ]
                        }
                    },
                    "response": []
                },
                {
                    "name": "GET Relief Items (Danh sách nhu yếu phẩm)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/relief-items",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "relief-items"]
                        }
                    },
                    "response": []
                }
            ]
        },
        {
            "name": "5. Admin System & Users (Quản trị & Người dùng)",
            "item": [
                {
                    "name": "GET All Users (Danh sách người dùng)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/admin/users?query=",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "admin", "users"],
                            "query": [
                                {
                                    "key": "query",
                                    "value": "",
                                    "description": "Từ khóa tìm kiếm theo tên hoặc email"
                                }
                            ]
                        },
                        "description": "Dành cho Admin xem toàn bộ tài khoản trong hệ thống."
                    },
                    "response": []
                },
                {
                    "name": "POST Create User (Tạo tài khoản mới)",
                    "request": {
                        "method": "POST",
                        "header": [
                            {
                                "key": "Content-Type",
                                "value": "application/json"
                            }
                        ],
                        "body": {
                            "mode": "raw",
                            "raw": json.dumps({
                                "email": "coordinator_danang@rescue.vn",
                                "fullName": "Nguyễn Văn Điều Phối",
                                "phoneNumber": "0905123456",
                                "roleId": "ROLE_COORDINATOR"
                            }, indent=2)
                        },
                        "url": {
                            "raw": "{{base_url}}/api/v1/admin/users",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "admin", "users"]
                        }
                    },
                    "response": []
                },
                {
                    "name": "GET User Roles (Danh sách vai trò)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/admin/users/roles",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "admin", "users", "roles"]
                        }
                    },
                    "response": []
                },
                {
                    "name": "GET System Audit Logs (Xem log hệ thống)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/admin/system/logs",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "admin", "system", "logs"]
                        }
                    },
                    "response": []
                }
            ]
        },
        {
            "name": "6. Safety Reports & Danger Points (Báo cáo an toàn & Điểm nguy hiểm)",
            "item": [
                {
                    "name": "GET Safety Reports (Danh sách báo cáo an toàn)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/safety-reports",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "safety-reports"]
                        }
                    },
                    "response": []
                },
                {
                    "name": "GET Danger Points (Danh sách điểm nguy hiểm)",
                    "request": {
                        "method": "GET",
                        "header": [],
                        "url": {
                            "raw": "{{base_url}}/api/v1/danger-points",
                            "host": ["{{base_url}}"],
                            "path": ["api", "v1", "danger-points"]
                        }
                    },
                    "response": []
                }
            ]
        }
    ]
}

env = {
    "id": "c1f7a049-93e1-45a1-9488-7517ad83e740",
    "name": "Flood Rescue System - Local Environment",
    "values": [
        {
            "key": "base_url",
            "value": "http://localhost:8080",
            "type": "default",
            "enabled": True
        },
        {
            "key": "token",
            "value": "",
            "type": "secret",
            "enabled": True
        }
    ],
    "_postman_variable_scope": "environment"
}

with open(r"d:\duanbaolu\Flood-Rescue-Coordination-and-Relief-Management-System\Presentation.postman_collection.json", "w", encoding="utf-8") as f:
    json.dump(collection, f, ensure_ascii=False, indent=2)

with open(r"d:\duanbaolu\Flood-Rescue-Coordination-and-Relief-Management-System\Flood_Rescue_Environment.postman_environment.json", "w", encoding="utf-8") as f:
    json.dump(env, f, ensure_ascii=False, indent=2)

print("Postman collection and environment updated to base_url successfully.")

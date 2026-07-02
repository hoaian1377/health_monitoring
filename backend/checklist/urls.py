from django.urls import path
from . import views

urlpatterns = [
    # Checklist CRUD
    path('', views.ChecklistListView.as_view(), name='checklist-list'),
    path('create/', views.ChecklistCreateView.as_view(), name='checklist-create'),
    path('<int:pk>/', views.ChecklistDetailView.as_view(), name='checklist-detail'),

    # Checklist Items
    path('item/', views.ChecklistItemListView.as_view(), name='checklist-item-list'),
    path('item/create/', views.ChecklistItemCreateView.as_view(), name='checklist-item-create'),
    path('item/<int:pk>/', views.ChecklistItemDetailView.as_view(), name='checklist-item-detail'),
    path('item/<int:pk>/toggle/', views.toggle_checklist_item, name='checklist-item-toggle'),

    # Bulk operations
    path('<int:checklist_id>/items/bulk/', views.bulk_create_checklist_items, name='checklist-item-bulk'),
]

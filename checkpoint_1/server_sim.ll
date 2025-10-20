; ModuleID = 'server_sim.c'
source_filename = "server_sim.c"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-pc-linux-gnu"

%union.pthread_mutex_t = type { %struct.__pthread_mutex_s }
%struct.__pthread_mutex_s = type { i32, i32, i32, i32, i32, i16, i16, %struct.__pthread_internal_list }
%struct.__pthread_internal_list = type { %struct.__pthread_internal_list*, %struct.__pthread_internal_list* }
%struct.request_t = type { [8 x i8], [256 x i8], [16 x [64 x i8]], i32, i32 }
%union.pthread_cond_t = type { %struct.__pthread_cond_s }
%struct.__pthread_cond_s = type { %union.__atomic_wide_counter, %union.__atomic_wide_counter, [2 x i32], [2 x i32], i32, i32, [2 x i32] }
%union.__atomic_wide_counter = type { i64 }
%struct.db_entry = type { i64, i32, %struct.db_entry* }
%struct.timespec = type { i64, i64 }
%union.pthread_attr_t = type { i64, [48 x i8] }

@.str = private unnamed_addr constant [4 x i8] c"GET\00", align 1
@.str.1 = private unnamed_addr constant [5 x i8] c"POST\00", align 1
@.str.2 = private unnamed_addr constant [4 x i8] c"PUT\00", align 1
@.str.3 = private unnamed_addr constant [7 x i8] c"DELETE\00", align 1
@__const.make_request_text.methods = private unnamed_addr constant [4 x i8*] [i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i8* getelementptr inbounds ([5 x i8], [5 x i8]* @.str.1, i32 0, i32 0), i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str.2, i32 0, i32 0), i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.3, i32 0, i32 0)], align 16
@.str.4 = private unnamed_addr constant [7 x i8] c"/index\00", align 1
@.str.5 = private unnamed_addr constant [10 x i8] c"/api/item\00", align 1
@.str.6 = private unnamed_addr constant [12 x i8] c"/api/search\00", align 1
@.str.7 = private unnamed_addr constant [12 x i8] c"/api/update\00", align 1
@.str.8 = private unnamed_addr constant [12 x i8] c"/static/img\00", align 1
@.str.9 = private unnamed_addr constant [65 x i8] c"%s %s HTTP/1.1\0D\0AHost: example\0D\0AX-Client: %d\0D\0AX-Trace: %016lx\0D\0A\0D\0A\00", align 1
@qlock = internal global %union.pthread_mutex_t zeroinitializer, align 8
@req_queue = internal global [1024 x %struct.request_t] zeroinitializer, align 16
@q_tail = internal global i32 0, align 4
@qcond = internal global %union.pthread_cond_t zeroinitializer, align 8
@q_head = internal global i32 0, align 4
@.str.10 = private unnamed_addr constant [3 x i8] c"\0D\0A\00", align 1
@.str.11 = private unnamed_addr constant [7 x i8] c"search\00", align 1
@db_lock = internal global %union.pthread_mutex_t zeroinitializer, align 8
@db_table = internal global [4096 x %struct.db_entry*] zeroinitializer, align 16
@.str.12 = private unnamed_addr constant [41 x i8] c"[%ld.%03ld] client=%d path=%s status=%d\0A\00", align 1
@.str.13 = private unnamed_addr constant [9 x i8] c"X-Client\00", align 1
@.str.14 = private unnamed_addr constant [23 x i8] c"OK path=%s dbv=%d d=%d\00", align 1
@.str.15 = private unnamed_addr constant [5 x i8] c"/api\00", align 1

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @make_request_text(i32 noundef %0, i8* noundef %1, i64 noundef %2, i64* noundef %3) #0 {
  %5 = alloca i32, align 4
  %6 = alloca i8*, align 8
  %7 = alloca i64, align 8
  %8 = alloca i64*, align 8
  %9 = alloca [4 x i8*], align 16
  %10 = alloca [5 x i8*], align 16
  %11 = alloca i32, align 4
  %12 = alloca i32, align 4
  store i32 %0, i32* %5, align 4
  store i8* %1, i8** %6, align 8
  store i64 %2, i64* %7, align 8
  store i64* %3, i64** %8, align 8
  %13 = bitcast [4 x i8*]* %9 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 16 %13, i8* align 16 bitcast ([4 x i8*]* @__const.make_request_text.methods to i8*), i64 32, i1 false)
  %14 = bitcast [5 x i8*]* %10 to i8*
  call void @llvm.memset.p0i8.i64(i8* align 16 %14, i8 0, i64 40, i1 false)
  %15 = bitcast i8* %14 to [5 x i8*]*
  %16 = getelementptr inbounds [5 x i8*], [5 x i8*]* %15, i32 0, i32 0
  store i8* getelementptr inbounds ([7 x i8], [7 x i8]* @.str.4, i32 0, i32 0), i8** %16, align 16
  %17 = getelementptr inbounds [5 x i8*], [5 x i8*]* %15, i32 0, i32 1
  store i8* getelementptr inbounds ([10 x i8], [10 x i8]* @.str.5, i32 0, i32 0), i8** %17, align 8
  %18 = getelementptr inbounds [5 x i8*], [5 x i8*]* %15, i32 0, i32 2
  store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.6, i32 0, i32 0), i8** %18, align 16
  %19 = getelementptr inbounds [5 x i8*], [5 x i8*]* %15, i32 0, i32 3
  store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.7, i32 0, i32 0), i8** %19, align 8
  %20 = getelementptr inbounds [5 x i8*], [5 x i8*]* %15, i32 0, i32 4
  store i8* getelementptr inbounds ([12 x i8], [12 x i8]* @.str.8, i32 0, i32 0), i8** %20, align 16
  %21 = load i64*, i64** %8, align 8
  %22 = call i64 @xorshift64(i64* noundef %21)
  %23 = urem i64 %22, 4
  %24 = trunc i64 %23 to i32
  store i32 %24, i32* %11, align 4
  %25 = load i64*, i64** %8, align 8
  %26 = call i64 @xorshift64(i64* noundef %25)
  %27 = urem i64 %26, 5
  %28 = trunc i64 %27 to i32
  store i32 %28, i32* %12, align 4
  %29 = load i8*, i8** %6, align 8
  %30 = load i64, i64* %7, align 8
  %31 = load i32, i32* %11, align 4
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds [4 x i8*], [4 x i8*]* %9, i64 0, i64 %32
  %34 = load i8*, i8** %33, align 8
  %35 = load i32, i32* %12, align 4
  %36 = sext i32 %35 to i64
  %37 = getelementptr inbounds [5 x i8*], [5 x i8*]* %10, i64 0, i64 %36
  %38 = load i8*, i8** %37, align 8
  %39 = load i32, i32* %5, align 4
  %40 = load i64*, i64** %8, align 8
  %41 = call i64 @xorshift64(i64* noundef %40)
  %42 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* noundef %29, i64 noundef %30, i8* noundef getelementptr inbounds ([65 x i8], [65 x i8]* @.str.9, i64 0, i64 0), i8* noundef %34, i8* noundef %38, i32 noundef %39, i64 noundef %41) #7
  ret void
}

; Function Attrs: argmemonly nofree nounwind willreturn
declare void @llvm.memcpy.p0i8.p0i8.i64(i8* noalias nocapture writeonly, i8* noalias nocapture readonly, i64, i1 immarg) #1

; Function Attrs: argmemonly nofree nounwind willreturn writeonly
declare void @llvm.memset.p0i8.i64(i8* nocapture writeonly, i8, i64, i1 immarg) #2

; Function Attrs: noinline nounwind optnone uwtable
define internal i64 @xorshift64(i64* noundef %0) #0 {
  %2 = alloca i64*, align 8
  %3 = alloca i64, align 8
  store i64* %0, i64** %2, align 8
  %4 = load i64*, i64** %2, align 8
  %5 = load i64, i64* %4, align 8
  store i64 %5, i64* %3, align 8
  %6 = load i64, i64* %3, align 8
  %7 = shl i64 %6, 13
  %8 = load i64, i64* %3, align 8
  %9 = xor i64 %8, %7
  store i64 %9, i64* %3, align 8
  %10 = load i64, i64* %3, align 8
  %11 = lshr i64 %10, 7
  %12 = load i64, i64* %3, align 8
  %13 = xor i64 %12, %11
  store i64 %13, i64* %3, align 8
  %14 = load i64, i64* %3, align 8
  %15 = shl i64 %14, 17
  %16 = load i64, i64* %3, align 8
  %17 = xor i64 %16, %15
  store i64 %17, i64* %3, align 8
  %18 = load i64, i64* %3, align 8
  %19 = load i64*, i64** %2, align 8
  store i64 %18, i64* %19, align 8
  %20 = load i64, i64* %3, align 8
  ret i64 %20
}

; Function Attrs: nounwind
declare i32 @snprintf(i8* noundef, i64 noundef, i8* noundef, ...) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @enqueue_request(%struct.request_t* noundef %0) #0 {
  %2 = alloca %struct.request_t*, align 8
  store %struct.request_t* %0, %struct.request_t** %2, align 8
  %3 = call i32 @pthread_mutex_lock(%union.pthread_mutex_t* noundef @qlock) #7
  %4 = load i32, i32* @q_tail, align 4
  %5 = sext i32 %4 to i64
  %6 = getelementptr inbounds [1024 x %struct.request_t], [1024 x %struct.request_t]* @req_queue, i64 0, i64 %5
  %7 = load %struct.request_t*, %struct.request_t** %2, align 8
  %8 = bitcast %struct.request_t* %6 to i8*
  %9 = bitcast %struct.request_t* %7 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 16 %8, i8* align 4 %9, i64 1296, i1 false)
  %10 = load i32, i32* @q_tail, align 4
  %11 = add nsw i32 %10, 1
  %12 = srem i32 %11, 1024
  store i32 %12, i32* @q_tail, align 4
  %13 = call i32 @pthread_cond_signal(%union.pthread_cond_t* noundef @qcond) #7
  %14 = call i32 @pthread_mutex_unlock(%union.pthread_mutex_t* noundef @qlock) #7
  ret void
}

; Function Attrs: nounwind
declare i32 @pthread_mutex_lock(%union.pthread_mutex_t* noundef) #3

; Function Attrs: nounwind
declare i32 @pthread_cond_signal(%union.pthread_cond_t* noundef) #3

; Function Attrs: nounwind
declare i32 @pthread_mutex_unlock(%union.pthread_mutex_t* noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @dequeue_request(%struct.request_t* noundef %0) #0 {
  %2 = alloca %struct.request_t*, align 8
  store %struct.request_t* %0, %struct.request_t** %2, align 8
  %3 = call i32 @pthread_mutex_lock(%union.pthread_mutex_t* noundef @qlock) #7
  br label %4

4:                                                ; preds = %8, %1
  %5 = load i32, i32* @q_head, align 4
  %6 = load i32, i32* @q_tail, align 4
  %7 = icmp eq i32 %5, %6
  br i1 %7, label %8, label %10

8:                                                ; preds = %4
  %9 = call i32 @pthread_cond_wait(%union.pthread_cond_t* noundef @qcond, %union.pthread_mutex_t* noundef @qlock)
  br label %4, !llvm.loop !6

10:                                               ; preds = %4
  %11 = load %struct.request_t*, %struct.request_t** %2, align 8
  %12 = load i32, i32* @q_head, align 4
  %13 = sext i32 %12 to i64
  %14 = getelementptr inbounds [1024 x %struct.request_t], [1024 x %struct.request_t]* @req_queue, i64 0, i64 %13
  %15 = bitcast %struct.request_t* %11 to i8*
  %16 = bitcast %struct.request_t* %14 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %15, i8* align 16 %16, i64 1296, i1 false)
  %17 = load i32, i32* @q_head, align 4
  %18 = add nsw i32 %17, 1
  %19 = srem i32 %18, 1024
  store i32 %19, i32* @q_head, align 4
  %20 = call i32 @pthread_mutex_unlock(%union.pthread_mutex_t* noundef @qlock) #7
  ret i32 0
}

declare i32 @pthread_cond_wait(%union.pthread_cond_t* noundef, %union.pthread_mutex_t* noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @parse_request_text(i8* noundef %0, %struct.request_t* noundef %1) #0 {
  %3 = alloca i8*, align 8
  %4 = alloca %struct.request_t*, align 8
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  %7 = alloca i8*, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i32, align 4
  store i8* %0, i8** %3, align 8
  store %struct.request_t* %1, %struct.request_t** %4, align 8
  %10 = load i8*, i8** %3, align 8
  store i8* %10, i8** %5, align 8
  store i32 0, i32* %6, align 4
  br label %11

11:                                               ; preds = %26, %2
  %12 = load i8*, i8** %5, align 8
  %13 = load i8, i8* %12, align 1
  %14 = sext i8 %13 to i32
  %15 = icmp ne i32 %14, 0
  br i1 %15, label %16, label %24

16:                                               ; preds = %11
  %17 = load i8*, i8** %5, align 8
  %18 = load i8, i8* %17, align 1
  %19 = sext i8 %18 to i32
  %20 = icmp ne i32 %19, 32
  br i1 %20, label %21, label %24

21:                                               ; preds = %16
  %22 = load i32, i32* %6, align 4
  %23 = icmp slt i32 %22, 7
  br label %24

24:                                               ; preds = %21, %16, %11
  %25 = phi i1 [ false, %16 ], [ false, %11 ], [ %23, %21 ]
  br i1 %25, label %26, label %36

26:                                               ; preds = %24
  %27 = load i8*, i8** %5, align 8
  %28 = getelementptr inbounds i8, i8* %27, i32 1
  store i8* %28, i8** %5, align 8
  %29 = load i8, i8* %27, align 1
  %30 = load %struct.request_t*, %struct.request_t** %4, align 8
  %31 = getelementptr inbounds %struct.request_t, %struct.request_t* %30, i32 0, i32 0
  %32 = load i32, i32* %6, align 4
  %33 = add nsw i32 %32, 1
  store i32 %33, i32* %6, align 4
  %34 = sext i32 %32 to i64
  %35 = getelementptr inbounds [8 x i8], [8 x i8]* %31, i64 0, i64 %34
  store i8 %29, i8* %35, align 1
  br label %11, !llvm.loop !8

36:                                               ; preds = %24
  %37 = load %struct.request_t*, %struct.request_t** %4, align 8
  %38 = getelementptr inbounds %struct.request_t, %struct.request_t* %37, i32 0, i32 0
  %39 = load i32, i32* %6, align 4
  %40 = sext i32 %39 to i64
  %41 = getelementptr inbounds [8 x i8], [8 x i8]* %38, i64 0, i64 %40
  store i8 0, i8* %41, align 1
  %42 = load i8*, i8** %5, align 8
  %43 = load i8, i8* %42, align 1
  %44 = sext i8 %43 to i32
  %45 = icmp eq i32 %44, 32
  br i1 %45, label %46, label %49

46:                                               ; preds = %36
  %47 = load i8*, i8** %5, align 8
  %48 = getelementptr inbounds i8, i8* %47, i32 1
  store i8* %48, i8** %5, align 8
  br label %49

49:                                               ; preds = %46, %36
  store i32 0, i32* %6, align 4
  br label %50

50:                                               ; preds = %65, %49
  %51 = load i8*, i8** %5, align 8
  %52 = load i8, i8* %51, align 1
  %53 = sext i8 %52 to i32
  %54 = icmp ne i32 %53, 0
  br i1 %54, label %55, label %63

55:                                               ; preds = %50
  %56 = load i8*, i8** %5, align 8
  %57 = load i8, i8* %56, align 1
  %58 = sext i8 %57 to i32
  %59 = icmp ne i32 %58, 32
  br i1 %59, label %60, label %63

60:                                               ; preds = %55
  %61 = load i32, i32* %6, align 4
  %62 = icmp slt i32 %61, 255
  br label %63

63:                                               ; preds = %60, %55, %50
  %64 = phi i1 [ false, %55 ], [ false, %50 ], [ %62, %60 ]
  br i1 %64, label %65, label %75

65:                                               ; preds = %63
  %66 = load i8*, i8** %5, align 8
  %67 = getelementptr inbounds i8, i8* %66, i32 1
  store i8* %67, i8** %5, align 8
  %68 = load i8, i8* %66, align 1
  %69 = load %struct.request_t*, %struct.request_t** %4, align 8
  %70 = getelementptr inbounds %struct.request_t, %struct.request_t* %69, i32 0, i32 1
  %71 = load i32, i32* %6, align 4
  %72 = add nsw i32 %71, 1
  store i32 %72, i32* %6, align 4
  %73 = sext i32 %71 to i64
  %74 = getelementptr inbounds [256 x i8], [256 x i8]* %70, i64 0, i64 %73
  store i8 %68, i8* %74, align 1
  br label %50, !llvm.loop !9

75:                                               ; preds = %63
  %76 = load %struct.request_t*, %struct.request_t** %4, align 8
  %77 = getelementptr inbounds %struct.request_t, %struct.request_t* %76, i32 0, i32 1
  %78 = load i32, i32* %6, align 4
  %79 = sext i32 %78 to i64
  %80 = getelementptr inbounds [256 x i8], [256 x i8]* %77, i64 0, i64 %79
  store i8 0, i8* %80, align 1
  %81 = load %struct.request_t*, %struct.request_t** %4, align 8
  %82 = getelementptr inbounds %struct.request_t, %struct.request_t* %81, i32 0, i32 3
  store i32 0, i32* %82, align 4
  %83 = load i8*, i8** %3, align 8
  %84 = call i8* @strstr(i8* noundef %83, i8* noundef getelementptr inbounds ([3 x i8], [3 x i8]* @.str.10, i64 0, i64 0)) #8
  store i8* %84, i8** %7, align 8
  %85 = load i8*, i8** %7, align 8
  %86 = icmp ne i8* %85, null
  br i1 %86, label %88, label %87

87:                                               ; preds = %75
  br label %158

88:                                               ; preds = %75
  %89 = load i8*, i8** %7, align 8
  %90 = getelementptr inbounds i8, i8* %89, i64 2
  store i8* %90, i8** %7, align 8
  br label %91

91:                                               ; preds = %155, %88
  %92 = load i8*, i8** %7, align 8
  %93 = icmp ne i8* %92, null
  br i1 %93, label %94, label %109

94:                                               ; preds = %91
  %95 = load i8*, i8** %7, align 8
  %96 = load i8, i8* %95, align 1
  %97 = sext i8 %96 to i32
  %98 = icmp ne i32 %97, 0
  br i1 %98, label %99, label %109

99:                                               ; preds = %94
  %100 = load i8*, i8** %7, align 8
  %101 = load i8, i8* %100, align 1
  %102 = sext i8 %101 to i32
  %103 = icmp ne i32 %102, 13
  br i1 %103, label %104, label %109

104:                                              ; preds = %99
  %105 = load %struct.request_t*, %struct.request_t** %4, align 8
  %106 = getelementptr inbounds %struct.request_t, %struct.request_t* %105, i32 0, i32 3
  %107 = load i32, i32* %106, align 4
  %108 = icmp slt i32 %107, 16
  br label %109

109:                                              ; preds = %104, %99, %94, %91
  %110 = phi i1 [ false, %99 ], [ false, %94 ], [ false, %91 ], [ %108, %104 ]
  br i1 %110, label %111, label %158

111:                                              ; preds = %109
  %112 = load i8*, i8** %7, align 8
  %113 = call i8* @strstr(i8* noundef %112, i8* noundef getelementptr inbounds ([3 x i8], [3 x i8]* @.str.10, i64 0, i64 0)) #8
  store i8* %113, i8** %8, align 8
  %114 = load i8*, i8** %8, align 8
  %115 = icmp ne i8* %114, null
  br i1 %115, label %117, label %116

116:                                              ; preds = %111
  br label %158

117:                                              ; preds = %111
  %118 = load i8*, i8** %8, align 8
  %119 = load i8*, i8** %7, align 8
  %120 = ptrtoint i8* %118 to i64
  %121 = ptrtoint i8* %119 to i64
  %122 = sub i64 %120, %121
  %123 = trunc i64 %122 to i32
  store i32 %123, i32* %9, align 4
  %124 = load i32, i32* %9, align 4
  %125 = icmp sgt i32 %124, 0
  br i1 %125, label %126, label %155

126:                                              ; preds = %117
  %127 = load i32, i32* %9, align 4
  %128 = icmp slt i32 %127, 64
  br i1 %128, label %129, label %155

129:                                              ; preds = %126
  %130 = load %struct.request_t*, %struct.request_t** %4, align 8
  %131 = getelementptr inbounds %struct.request_t, %struct.request_t* %130, i32 0, i32 2
  %132 = load %struct.request_t*, %struct.request_t** %4, align 8
  %133 = getelementptr inbounds %struct.request_t, %struct.request_t* %132, i32 0, i32 3
  %134 = load i32, i32* %133, align 4
  %135 = sext i32 %134 to i64
  %136 = getelementptr inbounds [16 x [64 x i8]], [16 x [64 x i8]]* %131, i64 0, i64 %135
  %137 = getelementptr inbounds [64 x i8], [64 x i8]* %136, i64 0, i64 0
  %138 = load i8*, i8** %7, align 8
  %139 = load i32, i32* %9, align 4
  %140 = sext i32 %139 to i64
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 4 %137, i8* align 1 %138, i64 %140, i1 false)
  %141 = load %struct.request_t*, %struct.request_t** %4, align 8
  %142 = getelementptr inbounds %struct.request_t, %struct.request_t* %141, i32 0, i32 2
  %143 = load %struct.request_t*, %struct.request_t** %4, align 8
  %144 = getelementptr inbounds %struct.request_t, %struct.request_t* %143, i32 0, i32 3
  %145 = load i32, i32* %144, align 4
  %146 = sext i32 %145 to i64
  %147 = getelementptr inbounds [16 x [64 x i8]], [16 x [64 x i8]]* %142, i64 0, i64 %146
  %148 = load i32, i32* %9, align 4
  %149 = sext i32 %148 to i64
  %150 = getelementptr inbounds [64 x i8], [64 x i8]* %147, i64 0, i64 %149
  store i8 0, i8* %150, align 1
  %151 = load %struct.request_t*, %struct.request_t** %4, align 8
  %152 = getelementptr inbounds %struct.request_t, %struct.request_t* %151, i32 0, i32 3
  %153 = load i32, i32* %152, align 4
  %154 = add nsw i32 %153, 1
  store i32 %154, i32* %152, align 4
  br label %155

155:                                              ; preds = %129, %126, %117
  %156 = load i8*, i8** %8, align 8
  %157 = getelementptr inbounds i8, i8* %156, i64 2
  store i8* %157, i8** %7, align 8
  br label %91, !llvm.loop !10

158:                                              ; preds = %87, %116, %109
  ret void
}

; Function Attrs: nounwind readonly willreturn
declare i8* @strstr(i8* noundef, i8* noundef) #5

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @business_logic_sim(i32 noundef %0, i8* noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8*, align 8
  %6 = alloca double, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  store i32 %0, i32* %4, align 4
  store i8* %1, i8** %5, align 8
  store volatile double 1.000000e+00, double* %6, align 8
  %9 = load i32, i32* %4, align 4
  %10 = srem i32 %9, 500
  %11 = add nsw i32 1000, %10
  store i32 %11, i32* %7, align 4
  %12 = load i8*, i8** %5, align 8
  %13 = call i8* @strstr(i8* noundef %12, i8* noundef getelementptr inbounds ([7 x i8], [7 x i8]* @.str.11, i64 0, i64 0)) #8
  %14 = icmp ne i8* %13, null
  br i1 %14, label %15, label %18

15:                                               ; preds = %2
  %16 = load i32, i32* %7, align 4
  %17 = mul nsw i32 %16, 2
  store i32 %17, i32* %7, align 4
  br label %18

18:                                               ; preds = %15, %2
  store i32 0, i32* %8, align 4
  br label %19

19:                                               ; preds = %41, %18
  %20 = load i32, i32* %8, align 4
  %21 = load i32, i32* %7, align 4
  %22 = icmp slt i32 %20, %21
  br i1 %22, label %23, label %44

23:                                               ; preds = %19
  %24 = load i32, i32* %8, align 4
  %25 = sitofp i32 %24 to double
  %26 = fmul double %25, 0x3FE3C6EF078A37FD
  %27 = load i32, i32* %8, align 4
  %28 = srem i32 %27, 7
  %29 = add nsw i32 1, %28
  %30 = sitofp i32 %29 to double
  %31 = fdiv double %26, %30
  %32 = load volatile double, double* %6, align 8
  %33 = fadd double %32, %31
  store volatile double %33, double* %6, align 8
  %34 = load i32, i32* %8, align 4
  %35 = and i32 %34, 511
  %36 = icmp eq i32 %35, 0
  br i1 %36, label %37, label %40

37:                                               ; preds = %23
  %38 = load volatile double, double* %6, align 8
  %39 = call double @llvm.fmuladd.f64(double %38, double 0x3FF000001AD7F29B, double 0x3EB0C6F7A0B5ED8D)
  store volatile double %39, double* %6, align 8
  br label %40

40:                                               ; preds = %37, %23
  br label %41

41:                                               ; preds = %40
  %42 = load i32, i32* %8, align 4
  %43 = add nsw i32 %42, 1
  store i32 %43, i32* %8, align 4
  br label %19, !llvm.loop !11

44:                                               ; preds = %19
  %45 = load volatile double, double* %6, align 8
  %46 = fptosi double %45 to i32
  %47 = srem i32 %46, 2
  %48 = icmp eq i32 %47, 0
  br i1 %48, label %49, label %50

49:                                               ; preds = %44
  store i32 1, i32* %3, align 4
  br label %51

50:                                               ; preds = %44
  store i32 0, i32* %3, align 4
  br label %51

51:                                               ; preds = %50, %49
  %52 = load i32, i32* %3, align 4
  ret i32 %52
}

; Function Attrs: nofree nosync nounwind readnone speculatable willreturn
declare double @llvm.fmuladd.f64(double, double, double) #6

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @db_lookup_update(i64 noundef %0, i32 noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i64, align 8
  %5 = alloca i32, align 4
  %6 = alloca i64, align 8
  %7 = alloca %struct.db_entry*, align 8
  %8 = alloca i32, align 4
  store i64 %0, i64* %4, align 8
  store i32 %1, i32* %5, align 4
  %9 = load i64, i64* %4, align 8
  %10 = urem i64 %9, 4096
  store i64 %10, i64* %6, align 8
  %11 = call i32 @pthread_mutex_lock(%union.pthread_mutex_t* noundef @db_lock) #7
  %12 = load i64, i64* %6, align 8
  %13 = getelementptr inbounds [4096 x %struct.db_entry*], [4096 x %struct.db_entry*]* @db_table, i64 0, i64 %12
  %14 = load %struct.db_entry*, %struct.db_entry** %13, align 8
  store %struct.db_entry* %14, %struct.db_entry** %7, align 8
  br label %15

15:                                               ; preds = %38, %2
  %16 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %17 = icmp ne %struct.db_entry* %16, null
  br i1 %17, label %18, label %42

18:                                               ; preds = %15
  %19 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %20 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %19, i32 0, i32 0
  %21 = load i64, i64* %20, align 8
  %22 = load i64, i64* %4, align 8
  %23 = icmp eq i64 %21, %22
  br i1 %23, label %24, label %38

24:                                               ; preds = %18
  %25 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %26 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %25, i32 0, i32 1
  %27 = load i32, i32* %26, align 8
  store i32 %27, i32* %8, align 4
  %28 = load i32, i32* %5, align 4
  %29 = icmp ne i32 %28, 0
  br i1 %29, label %30, label %35

30:                                               ; preds = %24
  %31 = load i32, i32* %8, align 4
  %32 = add nsw i32 %31, 1
  %33 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %34 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %33, i32 0, i32 1
  store i32 %32, i32* %34, align 8
  br label %35

35:                                               ; preds = %30, %24
  %36 = call i32 @pthread_mutex_unlock(%union.pthread_mutex_t* noundef @db_lock) #7
  %37 = load i32, i32* %8, align 4
  store i32 %37, i32* %3, align 4
  br label %59

38:                                               ; preds = %18
  %39 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %40 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %39, i32 0, i32 2
  %41 = load %struct.db_entry*, %struct.db_entry** %40, align 8
  store %struct.db_entry* %41, %struct.db_entry** %7, align 8
  br label %15, !llvm.loop !12

42:                                               ; preds = %15
  %43 = call noalias i8* @malloc(i64 noundef 24) #7
  %44 = bitcast i8* %43 to %struct.db_entry*
  store %struct.db_entry* %44, %struct.db_entry** %7, align 8
  %45 = load i64, i64* %4, align 8
  %46 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %47 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %46, i32 0, i32 0
  store i64 %45, i64* %47, align 8
  %48 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %49 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %48, i32 0, i32 1
  store i32 1, i32* %49, align 8
  %50 = load i64, i64* %6, align 8
  %51 = getelementptr inbounds [4096 x %struct.db_entry*], [4096 x %struct.db_entry*]* @db_table, i64 0, i64 %50
  %52 = load %struct.db_entry*, %struct.db_entry** %51, align 8
  %53 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %54 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %53, i32 0, i32 2
  store %struct.db_entry* %52, %struct.db_entry** %54, align 8
  %55 = load %struct.db_entry*, %struct.db_entry** %7, align 8
  %56 = load i64, i64* %6, align 8
  %57 = getelementptr inbounds [4096 x %struct.db_entry*], [4096 x %struct.db_entry*]* @db_table, i64 0, i64 %56
  store %struct.db_entry* %55, %struct.db_entry** %57, align 8
  %58 = call i32 @pthread_mutex_unlock(%union.pthread_mutex_t* noundef @db_lock) #7
  store i32 1, i32* %3, align 4
  br label %59

59:                                               ; preds = %42, %35
  %60 = load i32, i32* %3, align 4
  ret i32 %60
}

; Function Attrs: nounwind
declare noalias i8* @malloc(i64 noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i64 @fake_compress(i8* noundef %0, i64 noundef %1, i8* noundef %2, i64 noundef %3) #0 {
  %5 = alloca i64, align 8
  %6 = alloca i8*, align 8
  %7 = alloca i64, align 8
  %8 = alloca i8*, align 8
  %9 = alloca i64, align 8
  %10 = alloca i64, align 8
  %11 = alloca i64, align 8
  %12 = alloca i64, align 8
  %13 = alloca i32, align 4
  store i8* %0, i8** %6, align 8
  store i64 %1, i64* %7, align 8
  store i8* %2, i8** %8, align 8
  store i64 %3, i64* %9, align 8
  %14 = load i64, i64* %9, align 8
  %15 = icmp eq i64 %14, 0
  br i1 %15, label %16, label %17

16:                                               ; preds = %4
  store i64 0, i64* %5, align 8
  br label %76

17:                                               ; preds = %4
  store i64 0, i64* %10, align 8
  store i64 0, i64* %11, align 8
  br label %18

18:                                               ; preds = %71, %17
  %19 = load i64, i64* %11, align 8
  %20 = load i64, i64* %7, align 8
  %21 = icmp ult i64 %19, %20
  br i1 %21, label %22, label %27

22:                                               ; preds = %18
  %23 = load i64, i64* %10, align 8
  %24 = add i64 %23, 8
  %25 = load i64, i64* %9, align 8
  %26 = icmp ult i64 %24, %25
  br label %27

27:                                               ; preds = %22, %18
  %28 = phi i1 [ false, %18 ], [ %26, %22 ]
  br i1 %28, label %29, label %74

29:                                               ; preds = %27
  store i64 1469598103934665603, i64* %12, align 8
  store i32 0, i32* %13, align 4
  br label %30

30:                                               ; preds = %55, %29
  %31 = load i32, i32* %13, align 4
  %32 = icmp slt i32 %31, 8
  br i1 %32, label %33, label %40

33:                                               ; preds = %30
  %34 = load i64, i64* %11, align 8
  %35 = load i32, i32* %13, align 4
  %36 = sext i32 %35 to i64
  %37 = add i64 %34, %36
  %38 = load i64, i64* %7, align 8
  %39 = icmp ult i64 %37, %38
  br label %40

40:                                               ; preds = %33, %30
  %41 = phi i1 [ false, %30 ], [ %39, %33 ]
  br i1 %41, label %42, label %58

42:                                               ; preds = %40
  %43 = load i8*, i8** %6, align 8
  %44 = load i64, i64* %11, align 8
  %45 = load i32, i32* %13, align 4
  %46 = sext i32 %45 to i64
  %47 = add i64 %44, %46
  %48 = getelementptr inbounds i8, i8* %43, i64 %47
  %49 = load i8, i8* %48, align 1
  %50 = zext i8 %49 to i64
  %51 = load i64, i64* %12, align 8
  %52 = xor i64 %51, %50
  store i64 %52, i64* %12, align 8
  %53 = load i64, i64* %12, align 8
  %54 = mul i64 %53, 1099511628211
  store i64 %54, i64* %12, align 8
  br label %55

55:                                               ; preds = %42
  %56 = load i32, i32* %13, align 4
  %57 = add nsw i32 %56, 1
  store i32 %57, i32* %13, align 4
  br label %30, !llvm.loop !13

58:                                               ; preds = %40
  %59 = load i64, i64* %10, align 8
  %60 = add i64 %59, 8
  %61 = load i64, i64* %9, align 8
  %62 = icmp ule i64 %60, %61
  br i1 %62, label %63, label %70

63:                                               ; preds = %58
  %64 = load i8*, i8** %8, align 8
  %65 = load i64, i64* %10, align 8
  %66 = getelementptr inbounds i8, i8* %64, i64 %65
  %67 = bitcast i64* %12 to i8*
  call void @llvm.memcpy.p0i8.p0i8.i64(i8* align 1 %66, i8* align 8 %67, i64 8, i1 false)
  %68 = load i64, i64* %10, align 8
  %69 = add i64 %68, 8
  store i64 %69, i64* %10, align 8
  br label %70

70:                                               ; preds = %63, %58
  br label %71

71:                                               ; preds = %70
  %72 = load i64, i64* %11, align 8
  %73 = add i64 %72, 8
  store i64 %73, i64* %11, align 8
  br label %18, !llvm.loop !14

74:                                               ; preds = %27
  %75 = load i64, i64* %10, align 8
  store i64 %75, i64* %5, align 8
  br label %76

76:                                               ; preds = %74, %16
  %77 = load i64, i64* %5, align 8
  ret i64 %77
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @server_log(i32 noundef %0, i8* noundef %1, i32 noundef %2) #0 {
  %4 = alloca i32, align 4
  %5 = alloca i8*, align 8
  %6 = alloca i32, align 4
  %7 = alloca %struct.timespec, align 8
  store i32 %0, i32* %4, align 4
  store i8* %1, i8** %5, align 8
  store i32 %2, i32* %6, align 4
  %8 = call i32 @clock_gettime(i32 noundef 0, %struct.timespec* noundef %7) #7
  %9 = getelementptr inbounds %struct.timespec, %struct.timespec* %7, i32 0, i32 0
  %10 = load i64, i64* %9, align 8
  %11 = getelementptr inbounds %struct.timespec, %struct.timespec* %7, i32 0, i32 1
  %12 = load i64, i64* %11, align 8
  %13 = sdiv i64 %12, 1000000
  %14 = load i32, i32* %4, align 4
  %15 = load i8*, i8** %5, align 8
  %16 = load i32, i32* %6, align 4
  %17 = call i32 (i8*, ...) @printf(i8* noundef getelementptr inbounds ([41 x i8], [41 x i8]* @.str.12, i64 0, i64 0), i64 noundef %10, i64 noundef %13, i32 noundef %14, i8* noundef %15, i32 noundef %16)
  ret void
}

; Function Attrs: nounwind
declare i32 @clock_gettime(i32 noundef, %struct.timespec* noundef) #3

declare i32 @printf(i8* noundef, ...) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i8* @worker_fn(i8* noundef %0) #0 {
  %2 = alloca i8*, align 8
  %3 = alloca %struct.request_t, align 4
  %4 = alloca [4096 x i8], align 16
  %5 = alloca [1024 x i8], align 16
  %6 = alloca i64, align 8
  %7 = alloca i32, align 4
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  %10 = alloca i64, align 8
  %11 = alloca i32, align 4
  %12 = alloca [256 x i8], align 16
  %13 = alloca i32, align 4
  %14 = alloca i64, align 8
  store i8* %0, i8** %2, align 8
  %15 = load i8*, i8** %2, align 8
  br label %16

16:                                               ; preds = %1, %45, %50
  %17 = call i32 @dequeue_request(%struct.request_t* noundef %3)
  %18 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 4
  %19 = load i32, i32* %18, align 4
  %20 = getelementptr inbounds [4096 x i8], [4096 x i8]* %4, i64 0, i64 0
  %21 = call i32 @rand() #7
  %22 = sext i32 %21 to i64
  store i64 %22, i64* %6, align 8
  call void @make_request_text(i32 noundef %19, i8* noundef %20, i64 noundef 4096, i64* noundef %6)
  %23 = getelementptr inbounds [4096 x i8], [4096 x i8]* %4, i64 0, i64 0
  call void @parse_request_text(i8* noundef %23, %struct.request_t* noundef %3)
  store i32 0, i32* %7, align 4
  store i32 0, i32* %8, align 4
  br label %24

24:                                               ; preds = %39, %16
  %25 = load i32, i32* %8, align 4
  %26 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 3
  %27 = load i32, i32* %26, align 4
  %28 = icmp slt i32 %25, %27
  br i1 %28, label %29, label %42

29:                                               ; preds = %24
  %30 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 2
  %31 = load i32, i32* %8, align 4
  %32 = sext i32 %31 to i64
  %33 = getelementptr inbounds [16 x [64 x i8]], [16 x [64 x i8]]* %30, i64 0, i64 %32
  %34 = getelementptr inbounds [64 x i8], [64 x i8]* %33, i64 0, i64 0
  %35 = call i8* @strstr(i8* noundef %34, i8* noundef getelementptr inbounds ([9 x i8], [9 x i8]* @.str.13, i64 0, i64 0)) #8
  %36 = icmp ne i8* %35, null
  br i1 %36, label %37, label %38

37:                                               ; preds = %29
  store i32 1, i32* %7, align 4
  br label %42

38:                                               ; preds = %29
  br label %39

39:                                               ; preds = %38
  %40 = load i32, i32* %8, align 4
  %41 = add nsw i32 %40, 1
  store i32 %41, i32* %8, align 4
  br label %24, !llvm.loop !15

42:                                               ; preds = %37, %24
  %43 = load i32, i32* %7, align 4
  %44 = icmp ne i32 %43, 0
  br i1 %44, label %50, label %45

45:                                               ; preds = %42
  %46 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 4
  %47 = load i32, i32* %46, align 4
  %48 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 1
  %49 = getelementptr inbounds [256 x i8], [256 x i8]* %48, i64 0, i64 0
  call void @server_log(i32 noundef %47, i8* noundef %49, i32 noundef 401)
  br label %16

50:                                               ; preds = %42
  %51 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 4
  %52 = load i32, i32* %51, align 4
  %53 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 1
  %54 = getelementptr inbounds [256 x i8], [256 x i8]* %53, i64 0, i64 0
  %55 = call i32 @business_logic_sim(i32 noundef %52, i8* noundef %54)
  store i32 %55, i32* %9, align 4
  %56 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 4
  %57 = load i32, i32* %56, align 4
  %58 = sext i32 %57 to i64
  %59 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 1
  %60 = getelementptr inbounds [256 x i8], [256 x i8]* %59, i64 0, i64 0
  %61 = call i64 @strlen(i8* noundef %60) #8
  %62 = xor i64 %58, %61
  store i64 %62, i64* %10, align 8
  %63 = load i64, i64* %10, align 8
  %64 = load i32, i32* %9, align 4
  %65 = call i32 @db_lookup_update(i64 noundef %63, i32 noundef %64)
  store i32 %65, i32* %11, align 4
  %66 = getelementptr inbounds [256 x i8], [256 x i8]* %12, i64 0, i64 0
  %67 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 1
  %68 = getelementptr inbounds [256 x i8], [256 x i8]* %67, i64 0, i64 0
  %69 = load i32, i32* %11, align 4
  %70 = load i32, i32* %9, align 4
  %71 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* noundef %66, i64 noundef 256, i8* noundef getelementptr inbounds ([23 x i8], [23 x i8]* @.str.14, i64 0, i64 0), i8* noundef %68, i32 noundef %69, i32 noundef %70) #7
  store i32 %71, i32* %13, align 4
  %72 = getelementptr inbounds [256 x i8], [256 x i8]* %12, i64 0, i64 0
  %73 = load i32, i32* %13, align 4
  %74 = sext i32 %73 to i64
  %75 = getelementptr inbounds [1024 x i8], [1024 x i8]* %5, i64 0, i64 0
  %76 = call i64 @fake_compress(i8* noundef %72, i64 noundef %74, i8* noundef %75, i64 noundef 1024)
  store i64 %76, i64* %14, align 8
  %77 = load i64, i64* %14, align 8
  %78 = call i32 @rand() #7
  %79 = srem i32 %78, 200
  %80 = add nsw i32 200, %79
  %81 = call i32 @usleep(i32 noundef %80)
  %82 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 4
  %83 = load i32, i32* %82, align 4
  %84 = getelementptr inbounds %struct.request_t, %struct.request_t* %3, i32 0, i32 1
  %85 = getelementptr inbounds [256 x i8], [256 x i8]* %84, i64 0, i64 0
  call void @server_log(i32 noundef %83, i8* noundef %85, i32 noundef 200)
  br label %16
}

; Function Attrs: nounwind
declare i32 @rand() #3

; Function Attrs: nounwind readonly willreturn
declare i64 @strlen(i8* noundef) #5

declare i32 @usleep(i32 noundef) #4

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i8* @generator_fn(i8* noundef %0) #0 {
  %2 = alloca i8*, align 8
  %3 = alloca i64, align 8
  %4 = alloca i32, align 4
  %5 = alloca %struct.request_t, align 4
  store i8* %0, i8** %2, align 8
  %6 = load i8*, i8** %2, align 8
  %7 = ptrtoint i8* %6 to i64
  %8 = trunc i64 %7 to i32
  %9 = load i8*, i8** %2, align 8
  %10 = ptrtoint i8* %9 to i64
  %11 = add i64 88172645463325252, %10
  store i64 %11, i64* %3, align 8
  %12 = load i8*, i8** %2, align 8
  %13 = ptrtoint i8* %12 to i64
  %14 = trunc i64 %13 to i32
  store i32 %14, i32* %4, align 4
  br label %15

15:                                               ; preds = %1, %15
  %16 = load i32, i32* %4, align 4
  %17 = getelementptr inbounds %struct.request_t, %struct.request_t* %5, i32 0, i32 4
  store i32 %16, i32* %17, align 4
  %18 = getelementptr inbounds %struct.request_t, %struct.request_t* %5, i32 0, i32 0
  %19 = getelementptr inbounds [8 x i8], [8 x i8]* %18, i64 0, i64 0
  %20 = call i32 (i8*, i64, i8*, ...) @snprintf(i8* noundef %19, i64 noundef 8, i8* noundef getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0)) #7
  %21 = getelementptr inbounds %struct.request_t, %struct.request_t* %5, i32 0, i32 1
  %22 = getelementptr inbounds [256 x i8], [256 x i8]* %21, i64 0, i64 0
  %23 = call i8* @strncpy(i8* noundef %22, i8* noundef getelementptr inbounds ([5 x i8], [5 x i8]* @.str.15, i64 0, i64 0), i64 noundef 255) #7
  %24 = getelementptr inbounds %struct.request_t, %struct.request_t* %5, i32 0, i32 3
  store i32 0, i32* %24, align 4
  call void @enqueue_request(%struct.request_t* noundef %5)
  %25 = call i64 @xorshift64(i64* noundef %3)
  %26 = urem i64 %25, 10000
  %27 = add i64 1000, %26
  %28 = trunc i64 %27 to i32
  %29 = call i32 @usleep(i32 noundef %28)
  br label %15
}

; Function Attrs: nounwind
declare i8* @strncpy(i8* noundef, i8* noundef, i64 noundef) #3

; Function Attrs: noinline nounwind optnone uwtable
define dso_local void @db_init() #0 {
  %1 = alloca i32, align 4
  %2 = alloca i32, align 4
  %3 = alloca %struct.db_entry*, align 8
  store i32 0, i32* %1, align 4
  br label %4

4:                                                ; preds = %11, %0
  %5 = load i32, i32* %1, align 4
  %6 = icmp slt i32 %5, 4096
  br i1 %6, label %7, label %14

7:                                                ; preds = %4
  %8 = load i32, i32* %1, align 4
  %9 = sext i32 %8 to i64
  %10 = getelementptr inbounds [4096 x %struct.db_entry*], [4096 x %struct.db_entry*]* @db_table, i64 0, i64 %9
  store %struct.db_entry* null, %struct.db_entry** %10, align 8
  br label %11

11:                                               ; preds = %7
  %12 = load i32, i32* %1, align 4
  %13 = add nsw i32 %12, 1
  store i32 %13, i32* %1, align 4
  br label %4, !llvm.loop !16

14:                                               ; preds = %4
  store i32 0, i32* %2, align 4
  br label %15

15:                                               ; preds = %44, %14
  %16 = load i32, i32* %2, align 4
  %17 = icmp slt i32 %16, 256
  br i1 %17, label %18, label %47

18:                                               ; preds = %15
  %19 = call noalias i8* @malloc(i64 noundef 24) #7
  %20 = bitcast i8* %19 to %struct.db_entry*
  store %struct.db_entry* %20, %struct.db_entry** %3, align 8
  %21 = load i32, i32* %2, align 4
  %22 = mul nsw i32 %21, 7919
  %23 = sext i32 %22 to i64
  %24 = load %struct.db_entry*, %struct.db_entry** %3, align 8
  %25 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %24, i32 0, i32 0
  store i64 %23, i64* %25, align 8
  %26 = load i32, i32* %2, align 4
  %27 = srem i32 %26, 50
  %28 = load %struct.db_entry*, %struct.db_entry** %3, align 8
  %29 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %28, i32 0, i32 1
  store i32 %27, i32* %29, align 8
  %30 = load %struct.db_entry*, %struct.db_entry** %3, align 8
  %31 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %30, i32 0, i32 0
  %32 = load i64, i64* %31, align 8
  %33 = urem i64 %32, 4096
  %34 = getelementptr inbounds [4096 x %struct.db_entry*], [4096 x %struct.db_entry*]* @db_table, i64 0, i64 %33
  %35 = load %struct.db_entry*, %struct.db_entry** %34, align 8
  %36 = load %struct.db_entry*, %struct.db_entry** %3, align 8
  %37 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %36, i32 0, i32 2
  store %struct.db_entry* %35, %struct.db_entry** %37, align 8
  %38 = load %struct.db_entry*, %struct.db_entry** %3, align 8
  %39 = load %struct.db_entry*, %struct.db_entry** %3, align 8
  %40 = getelementptr inbounds %struct.db_entry, %struct.db_entry* %39, i32 0, i32 0
  %41 = load i64, i64* %40, align 8
  %42 = urem i64 %41, 4096
  %43 = getelementptr inbounds [4096 x %struct.db_entry*], [4096 x %struct.db_entry*]* @db_table, i64 0, i64 %42
  store %struct.db_entry* %38, %struct.db_entry** %43, align 8
  br label %44

44:                                               ; preds = %18
  %45 = load i32, i32* %2, align 4
  %46 = add nsw i32 %45, 1
  store i32 %46, i32* %2, align 4
  br label %15, !llvm.loop !17

47:                                               ; preds = %15
  ret void
}

; Function Attrs: noinline nounwind optnone uwtable
define dso_local i32 @main(i32 noundef %0, i8** noundef %1) #0 {
  %3 = alloca i32, align 4
  %4 = alloca i32, align 4
  %5 = alloca i8**, align 8
  %6 = alloca [4 x i64], align 16
  %7 = alloca [4 x i64], align 16
  %8 = alloca i32, align 4
  %9 = alloca i32, align 4
  store i32 0, i32* %3, align 4
  store i32 %0, i32* %4, align 4
  store i8** %1, i8*** %5, align 8
  %10 = load i32, i32* %4, align 4
  %11 = load i8**, i8*** %5, align 8
  %12 = call i64 @time(i64* noundef null) #7
  %13 = trunc i64 %12 to i32
  call void @srand(i32 noundef %13) #7
  call void @db_init()
  store i32 0, i32* %8, align 4
  br label %14

14:                                               ; preds = %30, %2
  %15 = load i32, i32* %8, align 4
  %16 = icmp slt i32 %15, 4
  br i1 %16, label %17, label %33

17:                                               ; preds = %14
  %18 = load i32, i32* %8, align 4
  %19 = sext i32 %18 to i64
  %20 = getelementptr inbounds [4 x i64], [4 x i64]* %6, i64 0, i64 %19
  %21 = call i32 @pthread_create(i64* noundef %20, %union.pthread_attr_t* noundef null, i8* (i8*)* noundef @worker_fn, i8* noundef null) #7
  %22 = load i32, i32* %8, align 4
  %23 = sext i32 %22 to i64
  %24 = getelementptr inbounds [4 x i64], [4 x i64]* %7, i64 0, i64 %23
  %25 = load i32, i32* %8, align 4
  %26 = add nsw i32 %25, 1
  %27 = sext i32 %26 to i64
  %28 = inttoptr i64 %27 to i8*
  %29 = call i32 @pthread_create(i64* noundef %24, %union.pthread_attr_t* noundef null, i8* (i8*)* noundef @generator_fn, i8* noundef %28) #7
  br label %30

30:                                               ; preds = %17
  %31 = load i32, i32* %8, align 4
  %32 = add nsw i32 %31, 1
  store i32 %32, i32* %8, align 4
  br label %14, !llvm.loop !18

33:                                               ; preds = %14
  store i32 0, i32* %9, align 4
  br label %34

34:                                               ; preds = %48, %33
  %35 = load i32, i32* %9, align 4
  %36 = icmp slt i32 %35, 4
  br i1 %36, label %37, label %51

37:                                               ; preds = %34
  %38 = load i32, i32* %9, align 4
  %39 = sext i32 %38 to i64
  %40 = getelementptr inbounds [4 x i64], [4 x i64]* %7, i64 0, i64 %39
  %41 = load i64, i64* %40, align 8
  %42 = call i32 @pthread_join(i64 noundef %41, i8** noundef null)
  %43 = load i32, i32* %9, align 4
  %44 = sext i32 %43 to i64
  %45 = getelementptr inbounds [4 x i64], [4 x i64]* %6, i64 0, i64 %44
  %46 = load i64, i64* %45, align 8
  %47 = call i32 @pthread_join(i64 noundef %46, i8** noundef null)
  br label %48

48:                                               ; preds = %37
  %49 = load i32, i32* %9, align 4
  %50 = add nsw i32 %49, 1
  store i32 %50, i32* %9, align 4
  br label %34, !llvm.loop !19

51:                                               ; preds = %34
  ret i32 0
}

; Function Attrs: nounwind
declare void @srand(i32 noundef) #3

; Function Attrs: nounwind
declare i64 @time(i64* noundef) #3

; Function Attrs: nounwind
declare i32 @pthread_create(i64* noundef, %union.pthread_attr_t* noundef, i8* (i8*)* noundef, i8* noundef) #3

declare i32 @pthread_join(i64 noundef, i8** noundef) #4

attributes #0 = { noinline nounwind optnone uwtable "frame-pointer"="all" "min-legal-vector-width"="0" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #1 = { argmemonly nofree nounwind willreturn }
attributes #2 = { argmemonly nofree nounwind willreturn writeonly }
attributes #3 = { nounwind "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #4 = { "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #5 = { nounwind readonly willreturn "frame-pointer"="all" "no-trapping-math"="true" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+cx8,+fxsr,+mmx,+sse,+sse2,+x87" "tune-cpu"="generic" }
attributes #6 = { nofree nosync nounwind readnone speculatable willreturn }
attributes #7 = { nounwind }
attributes #8 = { nounwind readonly willreturn }

!llvm.module.flags = !{!0, !1, !2, !3, !4}
!llvm.ident = !{!5}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{i32 7, !"PIC Level", i32 2}
!2 = !{i32 7, !"PIE Level", i32 2}
!3 = !{i32 7, !"uwtable", i32 1}
!4 = !{i32 7, !"frame-pointer", i32 2}
!5 = !{!"Ubuntu clang version 14.0.0-1ubuntu1.1"}
!6 = distinct !{!6, !7}
!7 = !{!"llvm.loop.mustprogress"}
!8 = distinct !{!8, !7}
!9 = distinct !{!9, !7}
!10 = distinct !{!10, !7}
!11 = distinct !{!11, !7}
!12 = distinct !{!12, !7}
!13 = distinct !{!13, !7}
!14 = distinct !{!14, !7}
!15 = distinct !{!15, !7}
!16 = distinct !{!16, !7}
!17 = distinct !{!17, !7}
!18 = distinct !{!18, !7}
!19 = distinct !{!19, !7}

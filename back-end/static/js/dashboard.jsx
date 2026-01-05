const { stats, recentList } = window.dashboardData;

const StatCard = ({ title, count, color, icon }) => {
    return (
        <div className="col-md-3">
            <div className={`card text-white mb-3 ${color}`} style={{borderRadius: '10px'}}>
                <div className="card-body">
                    <div className="d-flex justify-content-between align-items-center">
                        <div>
                            <h6 className="card-title text-uppercase mb-1">{title}</h6>
                            <h2 className="display-4 font-weight-bold">{count}</h2>
                        </div>
                        <div style={{fontSize: '40px', opacity: 0.5}}>
                            {icon}
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
};

const RecentTable = ({ list }) => {
    return (
        <div className="card shadow mb-4">
            <div className="card-header py-3 bg-white">
                <h6 className="m-0 font-weight-bold text-primary">⏱️ Hoạt động chấm công mới nhất</h6>
            </div>
            <div className="card-body p-0">
                <table className="table table-striped mb-0">
                    <thead className="thead-light">
                        <tr>
                            <th>Nhân Viên</th>
                            <th>Giờ Vào</th>
                            <th>Trạng Thái</th>
                        </tr>
                    </thead>
                    <tbody>
                        {list.length > 0 ? (
                            list.map((item, index) => (
                                <tr key={index}>
                                    <td className="font-weight-bold">{item.ten}</td>
                                    <td>{item.gio_vao}</td>
                                    <td>
                                        <span className={`badge ${item.trang_thai.includes("Muộn") ? "badge-danger" : "badge-success"}`} 
                                              style={{padding: '8px 12px', fontSize: '12px'}}>
                                            {item.trang_thai}
                                        </span>
                                    </td>
                                </tr>
                            ))
                        ) : (
                            <tr><td colSpan="3" className="text-center py-4">Chưa có dữ liệu hôm nay</td></tr>
                        )}
                    </tbody>
                </table>
            </div>
        </div>
    );
};

const DashboardApp = () => {
    return (
        <div className="container-fluid mt-4">
            <h2 className="mb-4 text-gray-800">📊 Tổng Quan Hệ Thống</h2>
            
            <div className="row">
                <StatCard title="Nhân Viên" count={stats.nv} color="bg-primary" icon="👥" />
                <StatCard title="Đã Chấm Công" count={stats.cham_cong} color="bg-success" icon="✅" />
                <StatCard title="Đi Muộn" count={stats.di_muon} color="bg-warning" icon="⚠️" />
                <StatCard title="Phòng Ban" count={stats.pb} color="bg-info" icon="🏢" />
            </div>

            <div className="row">
                <div className="col-lg-12">
                    <RecentTable list={recentList} />
                </div>
            </div>
        </div>
    );
};

// Render vào thẻ div id="react-root"
const root = ReactDOM.createRoot(document.getElementById('react-root'));
root.render(<DashboardApp />);